# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'
require 'active_support/core_ext/string/filters'

module I18n::Tasks::Translators
  class OpenAiTranslator < BaseTranslator
    # max allowed texts per request
    BATCH_SIZE = 25
    DEFAULT_SYSTEM_PROMPT = <<~PROMPT.squish
      You are a professional translator that translates content from the %{from} locale
      to the %{to} locale in an i18n locale array.

      The array has a structured format and contains multiple strings. Your task is to translate
      each of these strings and create a new array with the translated strings.

      HTML markups (enclosed in < and > characters) must not be changed under any circumstance.
      Variables (starting with %%{ and ending with }) must not be changed under any circumstance.
      Any provided keys must not be changed under any circumstance.

      If a "X__" prefixed interpolation is given for the "other" plural key, you should try and
      use that in the translation for any missing pluralizations keys that may represent
      multiples.
      The goal is to conform to the Unicode CLDR plural rules while maintaining a understandable
      translation.

      Keep in mind the context of all the strings for a more accurate translation.
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
      @translator ||= OpenAI::Client.new(access_token: api_key)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:openai_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.openai_translate.errors.no_api_key') if key.blank?

        key
      end
    end

    def model
      @model ||= @i18n_tasks.translation_config[:openai_model].presence || 'gpt-3.5-turbo'
    end

    def system_prompt
      @system_prompt ||= @i18n_tasks.translation_config[:openai_system_prompt].presence || DEFAULT_SYSTEM_PROMPT
    end

    def translate_values(list, from:, to:)
      results = []

      list.each_slice(BATCH_SIZE) do |batch|
        result = translate_batch(batch, from, to)
        results << result

        @progress_bar.progress += result.size
      end

      results.flatten
    end

    def translate_batch(batch, from, to, retry_count = 0)
      translations = translate(batch, from, to)
      result = JSON.parse(remove_json_markdown(translations))

      if result.size != batch.size
        if retry_count < RETRIES
          translate_batch(batch, from, to, retry_count)
        elsif retry_count == RETRIES
          # Try each string individually
          batch.each do |string|
            translate_batch([string], from, to, RETRIES + 1)
          end
        else
          error = I18n.t('i18n_tasks.openai_translate.errors.invalid_size', expected: batch.size, actual: result.size)
          fail ::I18n::Tasks::CommandError, error
        end
      end

      result
    rescue JSON::ParserError
      if retry_count < RETRIES
        translate_batch([string], from, to, retry_count + 1)
      else
        raise ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.openai_translate.errors.invalid_json')
      end
    end

    def remove_json_markdown(string)
      string.gsub(/^```json\s*(.*?)\s*```$/m, '\1').strip
    end

    def translate(values, from, to) # rubocop:disable Metrics/MethodLength
      messages = [
        {
          role: 'system',
          content: format(system_prompt, from: from, to: to, size: values.size)
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

      response = translator.chat(
        parameters: {
          model: model,
          messages: messages,
          temperature: 0.0,
          stream: false
        }
      )

      translations = response.dig('choices', 0, 'message', 'content')
      error = response['error']

      fail "AI error: #{error}" if error.present?

      translations
    end
  end
end
