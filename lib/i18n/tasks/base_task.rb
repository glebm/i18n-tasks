# coding: utf-8
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/relative_keys'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/source_keys'
require 'i18n/tasks/translation_data'
require 'i18n/tasks/translation'
require 'i18n/tasks/ignore_keys'
require 'i18n/tasks/missing_keys'
require 'i18n/tasks/untranslated_keys'
require 'i18n/tasks/unused_keys'

module I18n
  module Tasks
    class BaseTask
      include KeyPatternMatching
      include RelativeKeys
      include PluralKeys
      include SourceKeys
      include MissingKeys
      include UntranslatedKeys
      include UnusedKeys
      include TranslationData
      include Translation
      include IgnoreKeys

      # i18n-tasks config (defaults + config/i18n-tasks.yml)
      # @return [Hash{String => String,Hash,Array}]
      def config
        I18n::Tasks.config
      end

      def warn_deprecated(message)
        I18n::Tasks.warn_deprecated(message)
      end

    end
  end
end
