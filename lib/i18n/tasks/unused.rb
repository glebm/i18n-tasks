# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      def find_keys
        used_keys = find_source_keys.to_set
        r = []
        traverse base_locale_data do |key, value|
          r << [key, value] unless used_keys.include?(key) || pattern_key?(key) || ignore_key?(key, :unused)
        end
        r
      end
    end
  end
end
