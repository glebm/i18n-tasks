# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_keys(locale = base_locale)
        @unused_keys         ||= {}
        @unused_keys[locale] ||= begin
          keys = data[locale].traverse_map_if { |key, value|
            next if used_in_expr?(key) || ignore_key?(key, :unused)
            key = depluralize_key(key, locale)
            [key, value] unless used_key?(key)
          }.uniq
          KeyGroup.new keys, locale: locale, type: :unused
        end
      end

      def remove_unused!(locales = nil)
        locales ||= self.locales
        unused  = unused_keys
        locales.each do |locale|
          used_key_values = data[locale].traverse_map_if { |key, value|
            [key, value] unless unused.include?(depluralize_key(key, locale))
          }
          data[locale] = used_key_values
        end
      end
    end
  end
end
