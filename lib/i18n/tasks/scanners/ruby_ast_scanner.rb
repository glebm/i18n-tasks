# frozen_string_literal: true
require 'i18n/tasks/scanners/file_scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/ruby_ast_call_finder'
require 'parser/current'

# rubocop:disable Metrics/AbcSize,Metrics/BlockNesting,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
# TODO: make this class more readable.

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls using whitequark/parser
  class RubyAstScanner < FileScanner # rubocop:disable Metrics/ClassLength
    include RelativeKeys
    include AST::Sexp

    MAGIC_COMMENT_PREFIX = /\A.\s*i18n-tasks-use\s+/

    def initialize(messages: %i(t translate), receivers: [nil, s(:const, nil, :I18n)], **args)
      super(args)
      @parser               = ::Parser::CurrentRuby.new
      @magic_comment_parser = ::Parser::CurrentRuby.new
      @call_finder          = RubyAstCallFinder.new(messages: messages, receivers: receivers)
    end

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      @parser.reset
      ast, comments = @parser.parse_with_comments(make_buffer(path))

      results = @call_finder.collect_calls ast do |send_node, method_name|
        send_node_to_key_occurrence(send_node, method_name)
      end

      magic_comments  = comments.select { |comment| comment.text =~ MAGIC_COMMENT_PREFIX }
      comment_to_node = Parser::Source::Comment.associate_locations(ast, magic_comments).tap do |h|
        # transform_values is only available in ActiveSupport 4.2+
        h.each { |k, v| h[k] = v.first }
      end.invert
      results + magic_comments.flat_map do |comment|
        @parser.reset
        associated_node = comment_to_node[comment]
        @call_finder.collect_calls(
          @parser.parse(make_buffer(path, comment.text.sub(MAGIC_COMMENT_PREFIX, '').split(/\s+(?=t)/).join('; ')))
        ) do |send_node, _method_name|
          # method_name is not available at this stage
          send_node_to_key_occurrence(send_node, nil, location: associated_node || comment.location)
        end
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise ::I18n::Tasks::CommandError.new(e, "Error scanning #{path}: #{e.message}")
    end

    # @param send_node [Parser::AST::Node]
    # @param method_name [Symbol, nil]
    # @param location [Parser::Source::Map]
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def send_node_to_key_occurrence(send_node, method_name, location: send_node.loc)
      if (first_arg_node = send_node.children[2]) &&
         (key = extract_string(first_arg_node))
        if (second_arg_node = send_node.children[3]) &&
           second_arg_node.type == :hash
          if (scope_node = extract_hash_pair(second_arg_node, 'scope'))
            scope = extract_string(scope_node.children[1],
                                   array_join_with: '.', array_flatten: true, array_reject_blank: true)
            return nil if scope.nil? && scope_node.type != :nil
            key = [scope, key].join('.') unless scope == ''
          end
          default_arg = if (default_arg_node = extract_hash_pair(second_arg_node, 'default'))
                          extract_string(default_arg_node.children[1])
                        end
        end
        full_key = if send_node.children[0].nil?
                     # Relative keys only work if called via `t()` but not `I18n.t()`:
                     absolute_key(key, location.expression.source_buffer.name, calling_method: method_name)
                   else
                     key
                   end
        [full_key, range_to_occurrence(key, location.expression, default_arg: default_arg)]
      end
    end

    # Extract a hash pair with a given literal key.
    #
    # @param node [AST::Node] a node of type `:hash`.
    # @param key [String] node key as a string (indifferent symbol-string matching).
    # @return [AST::Node, nil] a node of type `:pair` or nil.
    def extract_hash_pair(node, key)
      node.children.detect do |child|
        next unless child.type == :pair
        key_node = child.children[0]
        %i(sym str).include?(key_node.type) && key_node.children[0].to_s == key
      end
    end

    # If the node type is of `%i(sym str int false true)`, return the value as a string.
    # Otherwise, if `config[:strict]` is `false` and the type is of `%i(dstr dsym)`,
    # return the source as if it were a string.
    #
    # @param node [Parser::AST::Node]
    # @param array_join_with [String, nil] if set to a string, arrays will be processed and their elements joined.
    # @param array_flatten [Boolean] if true, nested arrays are flattened,
    #     otherwise their source is copied and surrounded by #{}. No effect unless `array_join_with` is set.
    # @param array_reject_blank [Boolean] if true, empty strings and `nil`s are skipped.
    #      No effect unless `array_join_with` is set.
    # @return [String, nil] `nil` is returned only when a dynamic value is encountered in strict mode
    #     or the node type is not supported.
    def extract_string(node, array_join_with: nil, array_flatten: false, array_reject_blank: false)
      if %i(sym str int).include?(node.type)
        node.children[0].to_s
      elsif %i(true false).include?(node.type)
        node.type.to_s
      elsif :nil == node.type
        ''
      elsif :array == node.type && array_join_with
        extract_array_as_string(
          node,
          array_join_with:    array_join_with,
          array_flatten:      array_flatten,
          array_reject_blank: array_reject_blank
        ).tap do |str|
          # `nil` is returned when a dynamic value is encountered in strict mode. Propagate:
          return nil if str.nil?
        end
      elsif !config[:strict] && %i(dsym dstr).include?(node.type)
        node.children.map do |child|
          if %i(sym str).include?(child.type)
            child.children[0].to_s
          else
            child.loc.expression.source
          end
        end.join
      end
    end

    # Extract an array as a single string.
    #
    # @param array_join_with [String] joiner of the array elements.
    # @param array_flatten [Boolean] if true, nested arrays are flattened,
    #     otherwise their source is copied and surrounded by #{}.
    # @param array_reject_blank [Boolean] if true, empty strings and `nil`s are skipped.
    # @return [String, nil] `nil` is returned only when a dynamic value is encountered in strict mode.
    def extract_array_as_string(node, array_join_with:, array_flatten: false, array_reject_blank: false)
      children_strings = node.children.map do |child|
        if %i(sym str int true false).include?(child.type)
          extract_string child
        else
          # ignore dynamic argument in strict mode
          return nil if config[:strict]
          if %i(dsym dstr).include?(child.type) || (:array == child.type && array_flatten)
            extract_string(child, array_join_with: array_join_with)
          else
            "\#{#{child.loc.expression.source}}"
          end
        end
      end
      if array_reject_blank
        children_strings.reject! do |x|
          # empty strings and nils in the scope argument are ignored by i18n
          x == ''
        end
      end
      children_strings.join(array_join_with)
    end

    def keys_relative_to_calling_method?(path)
      /controllers|mailers/.match(path)
    end

    # @param raw_key [String]
    # @param range [Parser::Source::Range]
    # @param default_arg [String, nil]
    # @return [Results::Occurrence]
    def range_to_occurrence(raw_key, range, default_arg: nil)
      Results::Occurrence.new(
        path:        range.source_buffer.name,
        pos:         range.begin_pos,
        line_num:    range.line,
        line_pos:    range.column,
        line:        range.source_line,
        raw_key:     raw_key,
        default_arg: default_arg
      )
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
  end
end
# rubocop:enable Metrics/AbcSize,Metrics/BlockNesting,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
