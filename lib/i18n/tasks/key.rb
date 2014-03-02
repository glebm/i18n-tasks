require 'i18n/tasks/key/key_group'
require 'i18n/tasks/key/match_pattern'
require 'i18n/tasks/key/usages'

module I18n
  module Tasks
    # Container for i18n key and its attributes
    class Key
      include ::I18n::Tasks::Key::KeyGroup
      include ::I18n::Tasks::Key::MatchPattern
      include ::I18n::Tasks::Key::Usages

      attr_accessor :own_attr

      # @param [Array<Key, Value>|Hash|String] key_or_attr
      # @param [Hash] attr optional
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

      def ==(other)
        self.attr == other.attr
      end

      def inspect
        "#<#{self.class.name}#{attr.inspect}>"
      end

      def key
        @own_attr[:key]
      end

      alias to_s key

      def value
        @own_attr[:value]
      end
    end
  end
end
