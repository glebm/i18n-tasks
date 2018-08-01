# frozen_string_literal: true

require 'easy_translate'
require 'i18n/tasks/html_keys'
require 'i18n/tasks/base_translator'

module I18n::Tasks
  module GoogleTranslation
    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def google_translate_forest(forest, from)
      GoogleTranslator.new(self).translate_forest(forest, from)
    end
  end

  class GoogleTranslator < BaseTranslator
    SUPPORTED_LOCALES_WITH_REGION = %w[zh-CN zh-TW].freeze

    def translate_values(list, **options)
      EasyTranslate.translate(list, options)
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        api_key: api_key,
        from: to_google_translate_compatible_locale(from),
        to: to_google_translate_compatible_locale(to)
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

    # Convert 'es-ES' to 'es'
    def to_google_translate_compatible_locale(locale)
      return locale unless locale.include?('-') && !SUPPORTED_LOCALES_WITH_REGION.include?(locale)
      locale.split('-', 2).first
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:google_translate_api_key]
        # fallback with deprecation warning
        if @i18n_tasks.translation_config[:api_key]
          @i18n_tasks.warn_deprecated(
            'Please rename Google Translate API Key from `api_key` to `google_translate_api_key`.'
          )
          key ||= translation_config[:api_key]
        end
        fail CommandError, I18n.t('i18n_tasks.google_translate.errors.no_api_key') if key.blank?
        key
      end
    end
  end
end
