require 'set'
module I18n
  module Tasks
    class KeyGroup
      attr_reader :keys, :attr, :key_names

      include Enumerable
      delegate :size, :length, :each, to: :keys

      def initialize(keys, attr = {})
        @keys = if keys && !keys[0].is_a?(::I18n::Tasks::Key)
                  keys.map { |key| I18n::Tasks::Key.new(key) }
                else
                  keys.map(&:clone)
                end.each { |key| key.key_group = self }

        @keys_by_name = @keys.inject({}) { |h, k| h[k.key.to_s] = k; h }
        @key_names    = @keys.map(&:key)
        @attr         = attr
      end

      def get(key)
        @keys_by_name[key.to_s]
      end

      alias [] get

      def key_names_set
        @key_names_set ||= Set.new(@key_names)
      end

      def include?(key)
        key_names_set.include?(key.to_s)
      end

      # order, e.g: {locale: :asc, type: :desc, key: :asc}
      def sort!(&block)
        @keys.sort!(&block)
        @key_names = @keys.map(&:to_s)
        self
      end

      def sort_by_attr!(order)
        order_keys = order.keys
        sort! { |a, b|
          by = order_keys.detect { |by| a[by] != b[by] }
          order[by] == :desc ? b[by] <=> a[by] : a[by] <=> b[by]
        }
      end

      def to_a
        @array ||= keys.map(&:attr)
      end

      alias as_json to_a

      def merge(other)
        shared_attr = {}
        self.attr.each { |key, value| shared_attr[key] = value if other.attr[key] == value }
        self_inherited  = self.attr.except(*shared_attr.keys)
        other_inherited = other.attr.except(*shared_attr.keys)
        keys = self.keys.map { |k| Key.new(self_inherited.merge(k.own_attr)) } + other.keys.map { |k| Key.new(other_inherited.merge(k.own_attr)) }
        KeyGroup.new(keys, shared_attr)
      end

      alias + merge
    end
  end
end
