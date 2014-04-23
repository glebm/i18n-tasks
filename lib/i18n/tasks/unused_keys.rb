# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_keys(locale = base_locale)
        @unused_keys         ||= {}
        @unused_keys[locale] ||= begin
          keys = data[locale].keys(root: false).map { |key, value|
            next if used_in_expr?(key) || ignore_key?(key, :unused)
            key = depluralize_key(key, locale)
            key unless used_key?(key)
          }.compact.uniq
          KeyGroup.new keys, locale: locale, type: :unused
        end
      end

      def remove_unused!(locales = nil)
        locales ||= self.locales
        unused  = unused_keys
        locales.each do |locale|
          data[locale] = data[locale].select_keys(root: false) { |key, value|
            !unused.include?(depluralize_key(key, locale))
          }
        end
      end
    end
  end
end
