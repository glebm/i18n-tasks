# frozen_string_literal: true

require 'i18n/tasks/translators/deepl_translator.rb'
require 'i18n/tasks/translators/google_translator.rb'

module I18n::Tasks
  module Translation
    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def deepl_translate_forest(forest, from)
      Translators::DeeplTranslator.new(self).translate_forest(forest, from)
    end

    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def google_translate_forest(forest, from)
      Translators::GoogleTranslator.new(self).translate_forest(forest, from)
    end
  end
end
