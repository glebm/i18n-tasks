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

    def handler_missing(node)
      node.updated(
        nil,
        node.children.map { |child| node?(child) ? process(child) : child }
      )
    end

    private

    def node?(node)
      node.is_a?(::Parser::AST::Node)
    end
  end
end
