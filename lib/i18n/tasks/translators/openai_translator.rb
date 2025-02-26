# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'
require 'active_support/core_ext/string/filters'

module I18n::Tasks::Translators
  class OpenAiTranslator < BaseTranslator
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
        require 'openai'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'ruby-openai' to your Gemfile to use this command"
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
      I18n.t('i18n_tasks.openai_translate.errors.no_results')
    end

    private

    def translator
      @translator ||= OpenAI::Client.new(access_token: api_key, log_errors: true)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:openai_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.openai_translate.errors.no_api_key') if key.blank?

        key
      end
    end

    def model
      @model ||= @i18n_tasks.translation_config[:openai_model].presence || 'gpt-4o-mini'
    end

    def system_prompt
      @system_prompt ||=
        (@i18n_tasks.translation_config[:openai_system_prompt].presence || DEFAULT_SYSTEM_PROMPT)
        .concat("\n#{JSON_FORMAT_INSTRUCTIONS_SYSTEM_PROMPT}")
      @system_prompt
    end

    def translate_values(list, from:, to:)
      results = []

      list.each_slice(BATCH_SIZE) do |batch|
        translations = translate(batch, from, to)
        result = JSON.parse(translations)
        results << result

        @progress_bar.progress += result.size
      end

      results.flatten
    end

    def translate(values, from, to)
      response = translator.chat(
        parameters: {
          model: model,
          messages: build_messages(values, from, to),
          temperature: 0.0,
          response_format: { type: 'json_object' }
        }
      )

      translations = response.dig('choices', 0, 'message', 'content')
      error = response['error']

      fail "AI error: #{error}" if error.present?

      # Extract the array from the JSON object response
      result = JSON.parse(translations)
      result['translations'].to_json
    end

    def build_messages(values, from, to)
      [
        {
          role: 'system',
          content: format(system_prompt, from: from, to: to)
        },
        {
          role: 'user',
          content: "Translate this array: \n\n\n"
        },
        {
          role: 'user',
          content: values.to_json
        }
      ]
    end
  end
end
