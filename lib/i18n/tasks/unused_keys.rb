# frozen_string_literal: true

require "set"

module I18n
  module Tasks
    module UnusedKeys
      def unused_keys(locales: nil, strict: nil)
        locales = Array(locales).presence || self.locales
        locales.map { |locale| unused_tree(locale: locale, strict: strict) }.compact.reduce(:merge!)
      end

      # @param [String] locale
      # @param [Boolean] strict if true, do not match dynamic keys
      def unused_tree(locale: base_locale, strict: nil)
        used_key_names = used_tree(strict: true).key_names.to_set
        collapse_plural_nodes!(data[locale].select_keys do |key, _node|
          !ignore_key?(key, :unused) &&
            (strict || !used_in_expr?(key)) &&
            !key_used?(depluralize_key(key, locale), used_key_names)
        end)
      end

      private

      # A key is considered used if it is directly used, or if one of its ancestors is used
      # (e.g. `t(:section)` covers `section.item.title`).
      def key_used?(key, used_key_names)
        return true if used_key_names.include?(key)

        ancestor = key
        loop do
          next_ancestor = ancestor.sub(/\.[^.]+\z/, "")
          break if next_ancestor == ancestor

          return true if used_key_names.include?(next_ancestor)

          ancestor = next_ancestor
        end

        false
      end
    end
  end
end
