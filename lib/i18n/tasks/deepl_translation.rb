# frozen_string_literal: true

require 'deepl'
require 'i18n/tasks/html_keys'
require 'i18n/tasks/base_translator'

module I18n::Tasks
  module DeeplTranslation
    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def deepl_translate_forest(forest, from)
      DeeplTranslator.new(self).translate_forest(forest, from)
    end
  end

  class DeeplTranslator < BaseTranslator
    def initialize(*)
      super
      configure_api_key!
    end

    def translate_values(list, from:, to:, **options)
      DeepL.translate(list, to_deepl_compatible_locale(from), to_deepl_compatible_locale(to), options).map(&:text)
    end

    def options_for_translate_values(**options)
      { ignore_tags: %w[i18n] }.merge(options)
    end

    def options_for_html
      { tag_handling: 'xml' }
    end

    def options_for_plain
      { preserve_formatting: true }
    end

    # @param [String] value
    # @return [String] 'hello, %{name}' => 'hello, <i18n>%{name}</i18n>'
    def replace_interpolations(value)
      value.gsub(INTERPOLATION_KEY_RE, '<i18n>\0</i18n>')
    end

    # @param [String] untranslated
    # @param [String] translated
    # @return [String] 'hello, <i18n>%{name}</i18n>' => 'hello, %{name}'
    def restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE
      translated.gsub(%r{<\/?i18n>}, '')
    rescue StandardError => e
      raise_interpolation_error(untranslated, translated, e)
    end

    def no_results_error_message
      I18n.t('i18n_tasks.deepl_translate.errors.no_results')
    end

    private

    # Convert 'es-ES' to 'ES'
    def to_deepl_compatible_locale(locale)
      locale.to_s.split('-', 2).first.upcase
    end

    def configure_api_key!
      api_key = @i18n_tasks.translation_config[:deepl_api_key]
      fail CommandError, I18n.t('i18n_tasks.deepl_translate.errors.no_api_key') if api_key.blank?
      DeepL.configure { |config| config.auth_key = api_key }
    end
  end
end
