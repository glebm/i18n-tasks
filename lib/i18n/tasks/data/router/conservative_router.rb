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
        out = {}
        not_found = Set.new
        forest.keys(root: false) do |key, node|
          locale_key = "#{locale}.#{key}"
          path = adapter[locale][locale_key].data[:path]

          # infer from base
          unless path
            path = base_tree["#{base_locale}.#{key}"].try(:data).try(:[], :path)
            path = path.try :sub, /(?<=[\/.])#{base_locale}(?=\.)/, locale
          end

          if path
            (out[path] ||= Set.new) << locale_key
          else
            not_found << locale_key
          end
        end
        out.each do |dest, keys|
          block.yield dest, forest.select_keys { |key, _| keys.include?(key) }
        end
        if not_found.present?
          super(locale, forest.select_keys { |key, _| not_found.include?(key) }, &block)
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

