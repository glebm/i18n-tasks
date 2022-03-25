# frozen_string_literal: true

require 'ast'
require 'set'
require 'i18n/tasks/scanners/local_ruby_parser'

module I18n::Tasks::Scanners
  class ErbAstProcessor
    include AST::Processor::Mixin
    def initialize
      super()
      @ruby_parser = LocalRubyParser.new(ignore_blocks: true)
      @comments = []
    end

    def process_and_extract_comments(ast)
      result = process(ast)
      [result, @comments]
    end

    def on_code(node)
      parsed, comments = @ruby_parser.parse(
        node.children[0],
        location: node.location
      )
      @comments.concat(comments)

      unless parsed.nil?
        parsed = parsed.updated(
          nil,
          parsed.children.map { |child| node?(child) ? process(child) : child }
        )
        node = node.updated(:send, parsed)
      end
      node
    end

    # @param node [::Parser::AST::Node]
    # @return [::Parser::AST::Node]
    def handler_missing(node)
      node = transform_misparsed_comment(node)
      node.updated(
        nil,
        node.children.map { |child| node?(child) ? process(child) : child }
      )
    end

    private

    # Works around incorrect handling of comments of the form:
    # <%# ... #>
    # (no space between % and #)
    #
    # With a space the AST is:
    #
    #     s(:erb, nil, nil,
    #       s(:code, " # this should not fail: ' "), nil)
    #
    # Without a space the AST is:
    #
    #     s(:erb,
    #       s(:indicator, "#"), nil,
    #       s(:code, " this should not fail: ' "), nil)
    # @param node [::Parser::AST::Node]
    # @return [::Parser::AST::Node]
    def transform_misparsed_comment(node)
      return node unless node.type == :erb && node.children.size == 4 &&
        node.children[0]&.type == :indicator && node.children[0].children[0] == "#" &&
        node.children[1].nil? &&
        node.children[2]&.type == :code &&
        node.children[3].nil?
      code_node = node.children[2]
      node.updated(
        nil,
        [nil, nil, code_node.updated(nil, ["##{code_node.children[0]}"]), nil]
      )
    end

    def node?(node)
      node.is_a?(::Parser::AST::Node)
    end
  end
end
