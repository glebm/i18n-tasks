# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      def unused_keys(opts = {})
        locales = Array(opts[:locales]).presence || self.locales
        locales.map { |locale| unused_tree locale }.compact.reduce(:merge!)
      end

      def unused_tree(locale = base_locale)
        collapse_plural_nodes! data[locale].select_keys { |key, _node|
          !ignore_key?(key, :unused) &&
              !used_in_expr?(key) &&
              !used_key?(depluralize_key(key, locale))
        }
      end

      def remove_unused!(locales = nil)
        locales ||= self.locales
        locales.each do |locale|
          unused       = unused_tree(locale).key_names.to_set
          data[locale] = data[locale].select_keys { |key, value|
            !unused.include?(depluralize_key(key, locale))
          }
        end
      end
    end
  end
end
