# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_tree(locale = base_locale)
        @unused_tree         ||= {}
        @unused_tree[locale] ||= begin
          data[locale].select_keys { |key, _node|
            !ignore_key?(key, :unused) &&
                !used_in_expr?(key) &&
                !used_key?(depluralize_key(key, locale))
          }
        end
      end

      def unused_key_names(locale = base_locale)
        @unused_key_names         ||= {}
        @unused_key_names[locale] ||= unused_tree(locale).key_names.map { |key| depluralize_key(key, locale) }.uniq
      end

      def unused_key_values(locale = base_locale)
        @unused_key_values         ||= {}
        @unused_key_values[locale] ||= unused_key_names(locale).map { |k| [k, t(k, locale)] }
      end

      def remove_unused!(locales = nil)
        locales ||= self.locales
        locales.each do |locale|
          unused  = unused_key_names(locale).to_set
          data[locale] = data[locale].select_keys { |key, value|
            !unused.include?(depluralize_key(key, locale))
          }
        end
      end
    end
  end
end
