# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def find_keys
        r = []
        d = self.data[base_locale]
        traverse d do |key, value|
          next if pattern_key?(key) || ignore_key?(key, :unused)
          key = depluralize_key(key, d)
          r << [key, value] unless used_key?(key)
        end
        r.uniq
      end
    end
  end
end