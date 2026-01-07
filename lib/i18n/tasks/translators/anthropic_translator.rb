# frozen_string_literal: true

require "i18n/tasks/translators/base_translator"
require "active_support/core_ext/string/filters"

module I18n::Tasks::Translators
  class AnthropicTranslator < BaseTranslator
    include ::I18n::Tasks::Data::LanguageNames

    # max allowed texts per request
    BATCH_SIZE = 50
    DEFAULT_SYSTEM_PROMPT = <<~PROMPT.squish
      You are a professional translator that translates content from the %{from} locale
      to the %{to} locale in an i18n locale array.

      The array has a structured format and contains multiple strings. Your task is to translate
      each of these strings and create a new array with the translated strings.

      HTML markups (enclosed in < and > characters) must not be changed under any circumstance.
      Variables (starting with %%{ and ending with }) must not be changed under any circumstance.

      Keep in mind the context of all the strings for a more accurate translation.
      It is CRITICAL you output only the result, without any additional information, code block syntax or comments.
    PROMPT
    JSON_FORMAT_INSTRUCTIONS_SYSTEM_PROMPT = <<~PROMPT.squish
      Return the translations as a JSON object with a 'translations' array containing the translated strings.
    PROMPT

    def initialize(*)
      begin
        require "anthropic"
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'anthropic-sdk-ruby' to your Gemfile to use this command"
      end
      super
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        from: from,
        to: to
      )
    end

    def options_for_html
      {}
    end

    def options_for_plain
      {}
    end

    def no_results_error_message
      I18n.t("i18n_tasks.anthropic_translate.errors.no_results")
    end

    private

    def translator
      @translator ||= Anthropic::Client.new(access_token: api_key)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:anthropic_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t("i18n_tasks.anthropic_translate.errors.no_api_key") if key.blank?

        key
      end
    end

    def model
      @model ||= @i18n_tasks.translation_config[:anthropic_model].presence || "claude-3-5-haiku-20241022"
    end

    def temperature
      @temperature ||= @i18n_tasks.translation_config[:anthropic_temperature].presence || 0.0
    end

    def max_tokens
      @max_tokens ||= @i18n_tasks.translation_config[:anthropic_max_tokens].presence || 4096
    end

    def system_prompt(to_locale)
      prompt = if locale_prompts[to_locale].present?
        locale_prompts[to_locale]
      else
        @i18n_tasks.translation_config[:anthropic_system_prompt].presence || DEFAULT_SYSTEM_PROMPT
      end

      prompt.concat("\n#{JSON_FORMAT_INSTRUCTIONS_SYSTEM_PROMPT}")
    end

    def locale_prompts
      @locale_prompts ||= @i18n_tasks.translation_config[:anthropic_locale_prompts] || {}
    end

    def translate_values(list, from:, to:)
      results = []

      list.each_slice(BATCH_SIZE) do |batch|
        result = translate(batch, from, to)
        results << result

        @progress_bar.progress += result.size
      end

      results.flatten
    end

    def translate(values, from, to)
      messages = build_messages(values, from, to)
      system = format(system_prompt(to), from: language_name(from), to: language_name(to))

      response = translator.messages.create(
        model: model,
        system_: system,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      )

      translations = response["content"][0]["text"]
      error = response.dig("error", "message")

      fail "AI error: #{error}" if error.present?

      # Extract the array from the JSON object response
      JSON.parse(translations)["translations"]
    end

    def build_messages(values, from, to)
      [
        {
          role: "user",
          content: "Translate this array: \n\n\n#{values.to_json}"
        }
      ]
    end
  end
end
