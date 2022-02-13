# frozen_string_literal: true

require 'ast'
require 'set'

module I18n::Tasks::Scanners
  class RubyAstCallFinder
    include AST::Processor::Mixin

    # @param receiver_messages [Set<Pair<[nil, AST::Node>, Symbol>>] The receiver-message pairs to look for.
    def initialize(receiver_messages:)
      super()
      @message_receivers = receiver_messages.each_with_object({}) do |(receiver, message), t|
        (t[message] ||= []) << receiver
      end
    end

    # @param root_node [Parser::AST:Node]
    # @yieldparam send_node [Parser::AST:Node]
    # @yieldparam method_name [nil, String] the surrounding method's name.
    def find_calls(root_node, &block)
      @callback = block
      process root_node
    ensure
      @callback = nil
    end

    # @param root_node (see #find_calls)
    # @yieldparam (see #find_calls)
    # @return [Array<block return values excluding nils>]
    def collect_calls(root_node)
      results = []
      find_calls root_node do |send_node, method_name|
        result = yield send_node, method_name
        results << result if result
      end
      results
    end

    def on_def(node)
      @method_name = node.children[0]
      handler_missing node
    ensure
      @method_name = nil
    end

    def on_send(send_node)
      receiver = send_node.children[0]
      message  = send_node.children[1]
      valid_receivers = @message_receivers[message]
      # use `any?` because `include?` checks type equality, but the receiver is a Parser::AST::Node != AST::Node.
      @callback.call(send_node, @method_name) if valid_receivers&.any? { |r| r == receiver }
      # always invoke handler_missing to get nested translations in children
      handler_missing send_node
      nil
    end

    def handler_missing(node)
      node.children.each { |child| process(child) if child.is_a?(::Parser::AST::Node) }
      nil
    end
  end
end
