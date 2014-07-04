# coding: utf-8
require 'i18n/tasks/command_error'
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/logging'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/used_keys'
require 'i18n/tasks/ignore_keys'
require 'i18n/tasks/missing_keys'
require 'i18n/tasks/unused_keys'
require 'i18n/tasks/google_translation'
require 'i18n/tasks/fill_tasks'
require 'i18n/tasks/locale_pathname'
require 'i18n/tasks/data'
require 'i18n/tasks/configuration'

module I18n
  module Tasks
    class BaseTask
      include KeyPatternMatching
      include PluralKeys
      include UsedKeys
      include IgnoreKeys
      include MissingKeys
      include UnusedKeys
      include FillTasks
      include GoogleTranslation
      include Logging
      include Configuration
      include Data

      def initialize(config = {})
        self.config = config || {}
      end

      def inspect
        "#{self.class.name}#{config_for_inspect}"
      end
    end
  end
end
