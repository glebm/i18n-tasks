# coding: utf-8
module I18n
  module Tasks
    class CommandError < StandardError
    end

    class CantAddChildrenToLeafError < CommandError
      def initialize(node)
        super("Failed to add children to #{node.full_key} because it has a value: #{node.value.inspect}")
      end
    end
  end
end

