# coding: utf-8
require 'term/ansicolor'
require 'i18n/tasks/usage_search'
require 'i18n/tasks/fuzzy_source_keys'
require 'i18n/tasks/plural_keys'
require 'i18n/tasks/relative_keys'
require 'i18n/tasks/translation_data'
require 'i18n/tasks/ignore_keys'

module I18n
  module Tasks
    class BaseTask
      include UsageSearch
      include PluralKeys
      include RelativeKeys
      include FuzzySourceKeys
      include TranslationData
      include IgnoreKeys

      # i18n-tasks config (defaults + config/i18n-tasks.yml)
      # @return [Hash{String => String,Hash,Array}]
      def config
        I18n::Tasks.config
      end
    end
  end
end
