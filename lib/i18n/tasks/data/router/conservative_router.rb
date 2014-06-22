# coding: utf-8
require 'i18n/tasks/data/router/pattern_router'

module I18n::Tasks
  module Data::Router
    # Keep the path, or infer from base locale
    class ConservativeRouter < PatternRouter
      def initialize(adapter, config)
        @adapter       = adapter
        @base_locale   = config[:base_locale]
        super
      end

      def route(locale, forest, &block)
        return to_enum(:route, locale, forest) unless block
        out = Hash.new { |hash, key| hash[key] = Set.new }
        not_found = Set.new
        forest.keys do |key, node|
          locale_key = "#{locale}.#{key}"
          path = adapter[locale][locale_key].try(:data).try(:[], :path)
          # infer from base
          unless path
            path = base_tree["#{base_locale}.#{key}"].try(:data).try(:[], :path)
            path = LocalePathname.replace_locale(path, base_locale, locale)
          end
          if path
            out[path] << locale_key
          else
            not_found << locale_key
          end
        end

        if not_found.present?
          # fall back to pattern router
          not_found_tree = forest.select_keys(root: true) { |key, _| not_found.include?(key) }
          super(locale, not_found_tree) { |path, tree|
            out[path] += tree.key_names(root: true)
          }
        end

        out.each do |dest, keys|
          block.yield dest, forest.select_keys(root: true) { |key, _| keys.include?(key) }
        end
      end

      protected

      def base_tree
        adapter[base_locale]
      end

      attr_reader :adapter, :base_locale
    end
  end
end

