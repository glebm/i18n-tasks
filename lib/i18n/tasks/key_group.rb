# coding: utf-8
require 'set'
module I18n
  module Tasks
    # Container for keys with shared attributes
    class KeyGroup
      attr_reader :keys, :attr, :key_names

      delegate :size, :length, :each, :[], :blank?, to: :keys
      include Enumerable

      def initialize(keys, attr = {})
        @keys = if keys && !keys[0].is_a?(::I18n::Tasks::Key)
                  keys.map { |key| I18n::Tasks::Key.new(key) }
                else
                  keys
                end
        @keys.each { |key| key.key_group ||= self } unless attr.delete(:orphan)

        @keys_by_name = @keys.inject({}) { |h, k| h[k.key.to_s] = k; h }
        @key_names    = @keys.map(&:key)
        @attr         = attr
      end

      def find_by_name(key)
        @keys_by_name[key.to_s]
      end

      def key_names_set
        @key_names_set ||= Set.new(@key_names)
      end

      def include?(key)
        key_names_set.include?(key.to_s)
      end

      def sort!(&block)
        @keys.sort!(&block)
        @key_names = @keys.map(&:to_s)
        self
      end

      # Sort keys by their attributes in order
      # @param [Hash] order e.g. {locale: :asc, type: :desc, key: :asc}
      def sort_by_attr!(order)
        order_keys = order.keys
        sort! { |a, b|
          by = order_keys.detect { |by| a[by] != b[by] }
          order[by] == :desc ? b[by] <=> a[by] : a[by] <=> b[by]
        }
        self
      end

      def to_a
        @array ||= keys.map(&:attr)
      end

      alias as_json to_a

      def merge(other)
        KeyGroup.new(keys + other.keys,
                     type: [attr[:type], other.attr[:type]].flatten.compact)
      end

      alias + merge
    end
  end
end
