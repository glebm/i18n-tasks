module I18n::Tasks
  module Data
    # A tree of keys. Roots are locales, leaves are values.
    class LocaleTree
      attr_reader :locale, :data

      def initialize(locale, data = {})
        @locale = locale.to_s
        @data   = to_tree_data(data)
      end

      def merge(other)
        self.class.new locale, data.deep_merge(to_tree_data(other))
      end

      alias + merge

      def to_hash
        {locale => data}
      end

      # @return [String,nil] translation of the key found in the passed hash or nil
      def t(key)
        key.to_s.split('.').inject(data) { |r, seg| r[seg] if r }
      end

      # traverse => map if yield(k, v)
      # @return [Array] mapped list
      def traverse_map_if
        list = []
        traverse do |k, v|
          mapped = yield(k, v)
          list << mapped if mapped
        end
        list
      end

      # traverse data, yielding with full key and value
      # @yield [full_key, value]
      # @return self
      def traverse
        q = [['', data]]
        until q.empty?
          path, value = q.pop
          if value.is_a?(Hash)
            value.each { |k, v| q << ["#{path}.#{k}", v] }
          else
            yield path[1..-1], value
          end
        end
        self
      end

      def to_tree_data(arg)
        self.class.to_tree_data(arg)
      end

      class << self
        def to_tree_data(any)
          if any.is_a?(Hash)
            any
          elsif any.is_a?(Array)
            list_to_tree_data any
          elsif any.is_a?(LocaleTree)
            any.data
          else
            raise "Can't get tree data from #{any.inspect}"
          end
        end

        def list_to_tree_data(list)
          key_values = list.sort_by(&:first)
          tree_data  = {}
          key_values.each do |key, value|
            key_segments            = key.to_s.split('.')
            node                    = key_segments[0..-2].inject(tree_data) do |subtree, seg|
              subtree[seg] ||= {}
            end
            node[key_segments.last] = value
          end
          tree_data
        end
      end
    end
  end
end
