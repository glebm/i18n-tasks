module I18n
  module Tasks
    class Key
      attr_accessor :own_attr, :key_group

      def initialize(key_or_attr, own_attr = {})
        @own_attr = if key_or_attr.is_a?(Array)
                      {key: key_or_attr[0], value: key_or_attr[1]}.merge(own_attr)
                    elsif key_or_attr.is_a?(Hash)
                      key_or_attr.merge(own_attr)
                    else
                      (own_attr || {}).merge(key: key_or_attr)
                    end
        @own_attr[:key] = @own_attr[:key].to_s
      end

      def [](prop)
        @own_attr[prop] || key_group.attr[prop]
      end

      def attr
        key_group.attr.merge @own_attr
      end

      def ==(other)
        self.attr == other.attr
      end

      def inspect
        "#<#{self.class.name}#{attr.inspect}>"
      end

      def clone_orphan
        clone.tap { |k| k.key_group = nil }
      end

      def key
        @own_attr[:key]
      end
      alias to_s key

      def value
        self[:value]
      end

      def locale
        self[:locale]
      end

      def type
        self[:type]
      end

      def src_pos
        self[:src_pos]
      end
    end
  end
end
