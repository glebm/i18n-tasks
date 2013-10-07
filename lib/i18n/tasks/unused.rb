# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def find_keys
        r = []
        traverse base_locale_data do |key, value|
          r << [key, value] unless used_key?(key) || pattern_key?(key) || ignore_key?(key, :unused)
        end
        r
      end
    end
  end
end
