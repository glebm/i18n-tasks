module I18n::Tasks
  module Data
    # A tree of keys. Roots are locales, leaves are values.
    class LocaleTree
      attr_reader :locale, :data

      def initialize(locale, data = {})
        @locale = locale.to_s
        if data.is_a?(Array)
          key_values = data.sort
          data       = {}
          key_values.each do |key, value|
            key_segments            = key.to_s.split('.')
            node                    = key_segments[0..-2].inject(data) do |subtree, seg|
              subtree[seg] ||= {}
            end
            node[key_segments.last] = value
          end
        end
        @data = data.with_indifferent_access
      end

      def merge(other)
        raise "Locales do not match #{locale} #{other.locale}" if locale != other.locale
        self.class.new locale, data.deep_merge(other.data)
      end

      def to_hash
        { locale => data }
      end

      # @return [String,nil] translation of the key found in the passed hash or nil
      def t(key)
        key.to_s.split('.').inject(data) { |r, seg| r[seg] if r }
      end

      def t_proc
        @t_proc ||= proc { |k| t(k, self.locale) }
      end

      # traverse => map if yield(k, v)
      def traverse_map_if
        list = []
        traverse do |k, v|
          mapped = yield(k, v)
          list << mapped if mapped
        end
        list
      end

      def traverse(&block)
        traverse_hash('', data, &block)
      end

      # traverse hash, yielding with full key and value
      # @param hash [Hash{String => String,Hash}] translation data to traverse
      # @yield [full_key, value] yields full key and value for every translation in #hash
      # @return [nil]
      def traverse_hash(path = '', hash)
        q = [[path, hash]]
        until q.empty?
          path, value = q.pop
          if value.is_a?(Hash)
            value.each { |k, v| q << ["#{path}.#{k}", v] }
          else
            yield path[1..-1], value
          end
        end
      end
    end
  end
end
