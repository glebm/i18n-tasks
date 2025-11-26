# frozen_string_literal: true

require "i18n/tasks/logging"
require "i18n/tasks/scanners/file_scanner"
require "i18n/tasks/scanners/relative_keys"
require "i18n/tasks/scanners/ruby_ast_call_finder"
require "i18n/tasks/scanners/ruby_parser_factory"
require "i18n/tasks/scanners/ast_matchers/default_i18n_subject_matcher"
require "i18n/tasks/scanners/ast_matchers/message_receivers_matcher"
require "i18n/tasks/scanners/ast_matchers/rails_model_matcher"
require "i18n/tasks/scanners/prism_scanners/visitor"
require "prism"

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls using whitequark/parser primarily and Prism if configured.
  class RubyScanner < FileScanner
    MAGIC_COMMENT_SKIP_PRISM = "i18n-tasks-skip-prism"
    include RelativeKeys
    include AST::Sexp
    include ::I18n::Tasks::Logging

    MAGIC_COMMENT_PREFIX = /\A.\s*i18n-tasks-use\s+/

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      if config[:prism]
        prism_parse_file(path)
      else
        ast_parser_parse_file(path)
      end
    rescue => e
      raise ::I18n::Tasks::CommandError.new(e, "Error scanning #{path}: #{e.message}")
    end

    def ast_parser_parse_file(path)
      setup_ast_parser
      ast, comments = path_to_ast_and_comments(path)

      ast_to_occurences(ast) + comments_to_occurences(path, ast, comments)
    end

    # Parse file on path and returns AST and comments.
    #
    # @param path Path to file to parse
    # @return [{Parser::AST::Node}, [Parser::Source::Comment]]
    def path_to_ast_and_comments(path)
      @parser.reset
      @parser.parse_with_comments(make_buffer(path))
    end

    # Create an {Parser::Source::Buffer} with the given contents.
    # The contents are assigned a {Parser::Source::Buffer#raw_source}.
    #
    # @param path [String] Path to assign as the buffer name.
    # @param contents [String]
    # @return [Parser::Source::Buffer] file contents
    def make_buffer(path, contents = read_file(path))
      Parser::Source::Buffer.new(path).tap do |buffer|
        buffer.raw_source = contents
      end
    end

    # Convert an array of {Parser::Source::Comment} to occurrences.
    #
    # @param path Path to file
    # @param ast Parser::AST::Node
    # @param comments [Parser::Source::Comment]
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def comments_to_occurences(path, ast, comments)
      magic_comments = comments.select { |comment| comment.text =~ MAGIC_COMMENT_PREFIX }
      comment_to_node = Parser::Source::Comment.associate_locations(ast, magic_comments).tap do |h|
        h.transform_values!(&:first)
      end.invert

      magic_comments.flat_map do |comment|
        @parser.reset
        associated_node = comment_to_node[comment]
        ast = @parser.parse(make_buffer(path, comment.text.sub(MAGIC_COMMENT_PREFIX, "").split(/\s+(?=t)/).join("; ")))
        calls = RubyAstCallFinder.new.collect_calls(ast)
        results = []

        # method_name is not available at this stage
        calls.each do |(send_node, _method_name)|
          @matchers.each do |matcher|
            result = matcher.convert_to_key_occurrences(
              send_node,
              nil,
              location: associated_node || comment.location
            )
            next unless result

            if result.is_a?(Array) && result.first.is_a?(Array)
              results.concat(result)
            else
              results << result
            end
          end
        end

        results
      end
    end

    # Convert {Parser::AST::Node} to occurrences.
    #
    # @param ast {Parser::Source::Comment}
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def ast_to_occurences(ast)
      calls = RubyAstCallFinder.new.collect_calls(ast)
      results = []
      calls.each do |send_node, method_name|
        @matchers.each do |matcher|
          result = matcher.convert_to_key_occurrences(send_node, method_name)
          next unless result

          if result.is_a?(Array) && result.first.is_a?(Array)
            results.concat(result)
          else
            results << result
          end
        end
      end

      results
    end

    def setup_ast_parser
      @parser ||= RubyParserFactory.create_parser
      @magic_comment_parser ||= RubyParserFactory.create_parser
      setup_ast_matchers
    end

    def setup_ast_matchers
      return if defined?(@matchers)

      if config[:receiver_messages]
        @matchers = config[:receiver_messages].map do |receiver, message|
          AstMatchers::MessageReceiversMatcher.new(
            receivers: [receiver],
            message: message,
            scanner: self
          )
        end
      else
        @matchers = %i[t t! translate translate!].map do |message|
          AstMatchers::MessageReceiversMatcher.new(
            receivers: [
              AST::Node.new(:const, [nil, :I18n]),
              nil
            ],
            message: message,
            scanner: self
          )
        end

        Array(config[:ast_matchers]).each do |class_name|
          @matchers << ActiveSupport::Inflector.constantize(class_name).new(scanner: self)
        end
      end
    end

    # ---------- Prism parser below ----------

    # Extract all occurrences of translate calls from the file at the given path.
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def prism_parse_file(path)
      # Need File.expand_path for JRuby
      process_prism_results(path, Prism.parse_file(File.expand_path(path)))
    end

    # This method handles only parsing to be able to test it properly.
    # Therefore it cannot handle the parsing itself.
    def process_prism_results(path, parse_results)
      comments = parse_results.attach_comments!
      parsed = parse_results.value

      # Check for magic comment to skip prism parsing, fallback to Parser AST
      return ast_parser_parse_file(path) if skip_prism_comment?(comments)

      visitor = I18n::Tasks::Scanners::PrismScanners::Visitor.new(
        rails: config[:prism] != "ruby",
        file_path: path
      )
      parsed.accept(visitor)

      occurrences = []
      visitor.process.each do |translation_call|
        result = translation_call.occurrences(path)
        next unless result

        if result.is_a?(Array) && result.first.is_a?(Array)
          occurrences.concat(result)
        else
          occurrences << result
        end
      end

      occurrences
    end

    def skip_prism_comment?(comments)
      comments.any? do |comment|
        content =
          comment.respond_to?(:slice) ? comment.slice : comment.location.slice
        content.include?(MAGIC_COMMENT_SKIP_PRISM)
      end
    end
  end

  class RubyAstScanner < RubyScanner
    def initialize(**args)
      warn_deprecated("RubyAstScanner is deprecated, use RubyScanner instead")
      super
    end
  end

  class PrismScanner < RubyScanner
    def initialize(**args)
      warn_deprecated('PrismScanner is deprecated, use RubyScanner with prism: "rails" or prism: "ruby" instead')
      super
    end
  end
end
