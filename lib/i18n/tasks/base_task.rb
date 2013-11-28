# coding: utf-8
require 'i18n/tasks/configuration'
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/relative_keys'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/source_keys'
require 'i18n/tasks/translation_data'
require 'i18n/tasks/ignore_keys'
require 'i18n/tasks/missing_keys'
require 'i18n/tasks/untranslated_keys'
require 'i18n/tasks/unused_keys'
require 'i18n/tasks/google_translation'
require 'i18n/tasks/fill_tasks'

module I18n
  module Tasks
    class BaseTask
      include Configuration
      include KeyPatternMatching
      include IgnoreKeys
      include DataTraversal
      include RelativeKeys
      include PluralKeys
      include SourceKeys
      include MissingKeys
      include UntranslatedKeys
      include UnusedKeys
      include TranslationData
      include FillTasks
      include GoogleTranslation

      def initialize(config = {})
        self.config = config || {}
      end
    end
  end
end
