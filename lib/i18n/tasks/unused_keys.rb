# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_keys(locale = base_locale)
        @unused_keys         ||= {}
        @unused_keys[locale] ||= ::I18n::Tasks::KeyGroup.new(
            traverse_map_if(data[locale]) { |key, value|
              next if pattern_key?(key) || ignore_key?(key, :unused)
              key = depluralize_key(locale, key)
              [key, value] unless used_key?(key)
            }.uniq, locale: locale, type: :unused)
      end

      def remove_unused!(locales = self.locales)
        unused = unused_keys
        locales.each do |locale|
          data[locale] = list_to_tree traverse_map_if(data[locale]) { |key, value|
            [key, value] unless unused.include?(depluralize_key(locale, key))
          }
        end
      end
    end
  end
end
