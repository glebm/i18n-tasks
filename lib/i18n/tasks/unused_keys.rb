# coding: utf-8
require 'set'

module I18n
  module Tasks
    module UnusedKeys
      def unused_keys(opts = {})
        locales = Array(opts[:locales]).presence || self.locales
        locales.map { |locale| unused_tree locale, opts[:strict] }.compact.reduce(:merge!)
      end

      # @param [String] locale
      # @param [Boolean] strict if true, do not match dynamic keys
      def unused_tree(locale = base_locale, strict = false)
        collapse_plural_nodes! data[locale].select_keys { |key, _node|
          !ignore_key?(key, :unused) &&
              (strict || !used_in_expr?(key)) &&
              !used_key?(depluralize_key(key, locale))
        }
      end
    end
  end
end
