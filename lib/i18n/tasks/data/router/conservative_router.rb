require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/data/tree/node'

module I18n::Tasks
  module Data::Router
    # Keep the path, or infer from base locale
    class ConservativeRouter
      def initialize(adapter, config)
        @adapter       = adapter
        @base_locale   = config[:base_locale]
        @routes_config = config[:write]
      end

      def route(locale, forest, &block)
        return to_enum(:route, locale, forest) unless block
        out = {}
        forest.keys(root: false) do |key, node|
          path = node.data[:path]

          # infer from base
          unless path
            path = base_tree["#{base_locale}.#{key}"].try(:data).try(:[], :path)
            path = path.try :sub, /(?<=[\/.])#{base_locale}(?=\.)/, locale
          end

          if path
            (out[path] ||= Set.new) << "#{locale}.#{key}"
          else
            raise "could not find path for #{locale}.#{key}"
          end
        end
        out.each do |dest, keys|
          block.yield dest, forest.select_keys { |key, _| keys.include?(key) }
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

