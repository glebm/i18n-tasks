# frozen_string_literal: true

require 'i18n/tasks/scanners/ruby_ast_scanner'
require 'i18n/tasks/scanners/local_ruby_parser'

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls in ERB-file better-html and ASTs
  class ErbAstScanner < RubyAstScanner
    DEFAULT_REGEXP = /<%(={1,2}|-|\#|%)?(.*?)([-=])?%>/m.freeze

    def initialize(**args)
      super(**args)
      @ruby_parser = LocalRubyParser.new(ignore_blocks: true)
    end

    private

    # Parse file on path and returns AST and comments.
    #
    # @param path Path to file to parse
    # @return [{Parser::AST::Node}, [Parser::Source::Comment]]
    def path_to_ast_and_comments(path)
      comments = []
      buffer = make_buffer(path)

      children = []
      buffer
        .source
        .scan(DEFAULT_REGEXP) do |indicator, code, tailch, _rspace|
          match = Regexp.last_match
          character = indicator ? indicator[0] : nil

          start = match.begin(0) + 2 + (character&.size || 0)
          stop = match.end(0) - 2 - (tailch&.size || 0)

          case character
          when '=', nil, '-'
            parsed, parsed_comments = handle_code(buffer, code, start, stop)
            comments.concat(parsed_comments)
            children << parsed unless parsed.nil?
          when '#', '#-'
            comments << handle_comment(buffer, start, stop)
          end
        end

      [root_node(children, buffer), comments]
    end

    def handle_code(buffer, code, start, stop)
      range = ::Parser::Source::Range.new(buffer, start, stop)
      location =
        Parser::Source::Map::Definition.new(
          range.begin,
          range.begin,
          range.begin,
          range.end
        )
      @ruby_parser.parse(code, location: location)
    end

    def handle_comment(buffer, start, stop)
      range = ::Parser::Source::Range.new(buffer, start, stop)
      ::Parser::Source::Comment.new(range)
    end

    def root_node(children, buffer)
      range = ::Parser::Source::Range.new(buffer, 0, buffer.source.size)
      location =
        Parser::Source::Map::Definition.new(
          range.begin,
          range.begin,
          range.begin,
          range.end
        )
      ::Parser::AST::Node.new(:erb, children, location: location)
    end
  end
end
