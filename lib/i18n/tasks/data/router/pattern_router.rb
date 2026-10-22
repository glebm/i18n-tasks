# frozen_string_literal: true

require "i18n/tasks/key_pattern_matching"
require "i18n/tasks/data/tree/node"

module I18n::Tasks
  module Data::Router
    # Route based on key name
    class PatternRouter
      include ::I18n::Tasks::KeyPatternMatching

      attr_reader :routes

      # @option data_config write [Array] of routes
      # @example
      #   {write:
      #     # keys matched top to bottom
      #     [['devise.*', 'config/locales/devise.%{locale}.yml'],
      #     # default catch-all (same as ['*', 'config/locales/%{locale}.yml'])
      #     'config/locales/%{locale}.yml']}
      def initialize(_adapter, data_config)
        @routes_config = data_config[:write]
        @routes = compile_routes @routes_config
      end

      # Route keys to destinations
      # @param forest [I18n::Tasks::Data::Tree::Siblings] forest roots are locales.
      # @yieldparam [String] dest_path
      # @yieldparam [I18n::Tasks::Data::Tree::Siblings] tree_slice
      # @return [Hash] mapping of destination => [ [key, value], ... ]
      def route(locale, forest, &block)
        return to_enum(:route, locale, forest) unless block

        locale = locale.to_s
        leaves_by_path = Hash.new { |hash, path| hash[path] = [] }
        forest.keys do |key, node|
          leaves_by_path[pattern_path(locale, key)] << node
        end
        leaves_by_path.each do |dest, leaves|
          block.yield dest, select_leaves(forest, leaves)
        end
      end

      protected

      def pattern_path(locale, key)
        pattern, path = routes.detect { |route| route[0] =~ key }
        fail CommandError, "Cannot route key #{key}. Routes are #{@routes_config.inspect}" unless pattern

        key_match = $~
        path = format(path, locale: locale)
        path.gsub!(/\\\d+/) { |m| key_match[m[1..].to_i] }
        path
      end

      # @return [Siblings] the subtree of forest holding these leaves, without walking the rest of the forest
      def select_leaves(forest, leaves)
        selected = Set.new
        leaves.each do |leaf|
          leaf.walk_to_root { |node| break unless selected.add?(node) }
        end
        forest.select_nodes { |node| selected.include?(node) }
      end

      private

      def compile_routes(routes)
        routes.map { |x| x.is_a?(String) ? ["*", x] : x }.map do |x|
          [compile_key_pattern(x[0]), x[1]]
        end
      end
    end
  end
end
