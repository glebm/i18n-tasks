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
        # Read paths without `%{locale}` give every locale the same files, so each locale's tree holds the others' keys
        reads = Array(config[:read])
        @shared_read = reads.any? && reads.none? { |pattern| pattern.include?("%{locale}") }
        super
      end

      def route(locale, forest, &block) # rubocop:disable Metrics/AbcSize
        return to_enum(:route, locale, forest) unless block

        locale = locale.to_s
        leaves_by_path = Hash.new { |hash, path| hash[path] = [] }
        locale_keys(locale, forest) do |key, node|
          key_parts = node.walk_from_root.drop(1).map(&:key)
          path = key_path(locale, key_parts) || read_path(locale, node)
          # infer from another locale
          unless path
            inferred_from = (locales - [locale]).detect { |loc| path = key_path(loc, key_parts, from: @shared_read ? locale : loc) }
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

      # Looked up by key parts: splitting the dotted key would lose blank keys (e.g. `''`) and split keys containing a dot.
      def key_path(locale, key_parts, from: locale)
        adapter[from].dig(locale, *key_parts).try(:data).try(:[], :path)
      end

      # The file a key was read from when the locale's own files don't include it, e.g. `en-GB` keys in `en.yml`.
      # A missing key only carries a guess, from the locale it is missing from.
      def read_path(locale, node)
        path = node.data[:path]
        return unless path && !node.data.key?(:missing_diff_locale) && adapter.respond_to?(:read_for?)

        path unless adapter.read_for?(path, locale)
      end

      attr_reader :adapter, :base_locale, :locales
    end
  end
end
