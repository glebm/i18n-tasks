require 'ast'
require 'set'
module I18n::Tasks::Scanners
  class RubyAstCallFinder
    include AST::Processor::Mixin

    # @param messages [Array<Symbol>] method names to intercept.
    # @param receivers [Array<nil, AST::Node>] receivers of the `messages` to intercept.
    def initialize(messages:, receivers:)
      super()
      @messages  = Set.new(messages)
      @receivers = Set.new(receivers)
    end

    def find_calls(node, &block)
      @callback = block
      process node
    end

    def on_def(node)
      @method_name = node.children[0]
      handler_missing node
    ensure
      @method_name = nil
    end

    def on_send(node)
      receiver = node.children[0]
      message  = node.children[1]
      if @messages.include?(message) &&
          # use `any?` because `include?` checks type equality, but the receiver is a Parser::AST::Node != AST::Node.
          @receivers.any? { |r| r == receiver }
        @callback.call(node, @method_name)
      else
        handler_missing node
      end
      nil
    end

    def handler_missing(node)
      node.children.each { |child| process(child) if child.is_a?(::Parser::AST::Node) }
      nil
    end
  end
end
