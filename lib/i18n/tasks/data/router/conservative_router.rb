# frozen_string_literal: true

require "i18n/tasks/data/router/pattern_router"

module I18n::Tasks
  module Data::Router
    # Keep the path, or infer from base locale
    class ConservativeRouter < PatternRouter
      def initialize(adapter, config)
        @adapter = adapter
        @base_locale = config[:base_locale]
        @locales = config[:locales]
        super
      end

      def route(locale, forest, &block) # rubocop:disable Metrics/AbcSize
        return to_enum(:route, locale, forest) unless block

        locale = locale.to_s
        leaves_by_path = Hash.new { |hash, path| hash[path] = [] }
        forest.keys do |key, node|
          path = key_path(locale, key, node)
          # infer from another locale
          unless path
            inferred_from = (locales - [locale]).detect { |loc| path = key_path(loc, key, node) }
            path = LocalePathname.replace_locale(path, inferred_from, locale) if inferred_from
          end
          # fall back to pattern router
          path ||= pattern_path(locale, key)
          leaves_by_path[path] << node
        end

        leaves_by_path.each do |dest, leaves|
          block.yield dest, select_leaves(forest, leaves)
        end
      end

      protected

      def base_tree
        adapter[base_locale]
      end

      # The dotted key also finds a key stored as `a.b` in one locale and as `a: {b:}` in another.
      # Splitting it loses blank keys (e.g. `''`) and splits keys containing a dot: look those up by key parts.
      def key_path(locale, key, node)
        tree = adapter[locale]
        tree["#{locale}.#{key}"].try(:data).try(:[], :path) ||
          tree.dig(locale, *node.walk_from_root.drop(1).map(&:key)).try(:data).try(:[], :path)
      end

      attr_reader :adapter, :base_locale, :locales
    end
  end
end
