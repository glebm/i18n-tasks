# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'

module I18n::Tasks::Translators
  class GoogleTranslator < BaseTranslator
    NEWLINE_PLACEHOLDER = '<br id=i18n />'
    def initialize(*)
      begin
        require 'easy_translate'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'easy_translate' to your Gemfile to use this command"
      end
      super
    end

    protected

    def translate_values(list, **options)
      restore_newlines(
        EasyTranslate.translate(
          replace_newlines_with_placeholder(list, options[:html]),
          options,
          format: :text
        ),
        options[:html]
      )
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        api_key: api_key,
        from: from,
        to: to
      )
    end

    def options_for_html
      { html: true }
    end

    def options_for_plain
      { format: 'text' }
    end

    def no_results_error_message
      I18n.t('i18n_tasks.google_translate.errors.no_results')
    end

    private

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:google_translate_api_key]
        # fallback with deprecation warning
        if @i18n_tasks.translation_config[:api_key]
          warn_deprecated(
            'Please rename Google Translate API Key from `api_key` to `google_translate_api_key`.'
          )
          key ||= translation_config[:api_key]
        end
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.google_translate.errors.no_api_key') if key.blank?

        key
      end
    end

    def replace_newlines_with_placeholder(list, html)
      return list unless html

      list.map do |value|
        value.gsub("\n", NEWLINE_PLACEHOLDER)
      end
    end

    def restore_newlines(translations, html)
      return translations unless html

      translations.map do |translation|
        translation.gsub("#{NEWLINE_PLACEHOLDER} ", "\n")
      end
    end
  end
end
