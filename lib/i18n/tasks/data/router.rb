require 'i18n/tasks/data/traversal'

module I18n::Tasks
  module Data
    module Router
      include ::I18n::Tasks::Data::Traversal
      include ::I18n::Tasks::KeyPatternMatching

      def compile_routes(routes)
        routes.map { |x| x.is_a?(String) ? ['*', x] : x }.map { |x|
          [compile_key_pattern(x[0]), x[1]]
        }
      end

      # Route keys to destinations
      # @param routes [Array] of routes
      # @example
      #   # keys matched top to bottom
      #   [['devise.*', 'config/locales/devise.%{locale}.yml'],
      #   # default catch-all (same as ['*', 'config/locales/%{locale}.yml'])
      #    'config/locales/%{locale}.yml']
      # @param values [Hash] locale tree. Keys are strings, and root is the locale.
      # @param route_args [Hash] route arguments, %-interpolated
      # @return [Hash] mapping of destination => [ [key, value], ... ]
      def route_values(routes, values, route_args = {}, &block)
        out = {}
        traverse values do |key, value|
          route     = routes.detect { |route| route[0] =~ key }
          key_match = $~
          path      = route[1] % route_args
          path.gsub!(/[\\]\d+/) { |m| key_match[m[1..-1].to_i] }
          (out[path] ||= []) << [key, value]
        end
        if block
          out.each(&block)
        else
          out
        end
      end

    end
  end
end

