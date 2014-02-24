# coding: utf-8
require 'i18n/tasks/configuration'
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/relative_keys'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/used_keys'
require 'i18n/tasks/translation_data'
require 'i18n/tasks/ignore_keys'
require 'i18n/tasks/missing_keys'
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
      include UsedKeys
      include MissingKeys
      include UnusedKeys
      include TranslationData
      include FillTasks
      include GoogleTranslation

      def initialize(config = {})
        self.config = config || {}
      end

      def in_task(&block)
        instance_exec(&block)
      end
    end
  end
end
