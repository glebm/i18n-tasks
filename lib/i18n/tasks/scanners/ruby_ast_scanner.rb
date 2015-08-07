require 'i18n/tasks/scanners/scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/ruby_ast_call_finder'
require 'parser/current'

module I18n::Tasks::Scanners
  # Scan for I18n.translate calls using whitequark/parser
  class RubyAstScanner < Scanner
    include AST::Processor::Mixin
    include RelativeKeys

    attr_reader :config

    CALL_FINDER_ARGS = {
        messages:  %i(t translate),
        receivers: [nil, AST::Node.new(:const, [nil, :I18n])]
    }

    def initialize(
        config: {},
        file_finder_provider: Files::CachingFileFinderProvider.new,
        file_reader: Files::CachingFileReader.new)
      @config      = config
      @file_reader = file_reader

      @file_finder          = file_finder_provider.get(**config.slice(:paths, :include, :exclude))
      # @type [Parser::Base]
      @parser               = ::Parser::CurrentRuby.new
      @magic_comment_parser = ::Parser::CurrentRuby.new
      @call_finder          = RubyAstCallFinder.new(**CALL_FINDER_ARGS)
    end

    # @return (see Scanner#keys)
    def keys
      (@file_finder.traverse_files { |path|
        scan_file(path)
      }.reduce(:+) || []).group_by(&:first).map { |key, keys_occurrences|
        Results::KeyOccurrences.new(key: key, occurrences: keys_occurrences.map(&:second))
      }
    end

    protected

    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      @parser.reset
      buffer            = Parser::Source::Buffer.new(path)
      buffer.raw_source = @file_reader.read_file(path)
      ast, comments     = @parser.parse_with_comments(buffer)
      results           = []
      @call_finder.find_calls ast do |node, method_name|
        if (result = node_to_key_occurrence(node, method_name, path))
          results << result
        end
      end
      results
    rescue Exception => e
      raise ::I18n::Tasks::CommandError.new(e, "Error scanning #{path}: #{e.message}")
    end

    # @param [Parser::AST::Node] send_node
    # @param [Symbol, nil] method_name
    # @return [nil, [key, Occurrence]] full absolute key name and the occurrence.
    def node_to_key_occurrence(send_node, method_name, path)
      if (first_arg_node = send_node.children[2]) &&
          (key = extract_string(first_arg_node))
        if (second_arg_node = send_node.children[3]) &&
            second_arg_node.type == :hash
          if (scope_node = extract_hash_pair(second_arg_node, 'scope'))
            key = [extract_string(scope_node.children[1]), key].join('.')
          end
          default_node = extract_hash_pair(second_arg_node, 'default')
        end
        [absolute_key(key, path, method_name),
         range_to_occurrence(send_node.loc.expression, default_arg_node: default_node)]
      end
    end

    # Convert a relative key to its absolute form.
    #
    # @param key [String]
    # @param path [String] path to the file
    # @param calling_method [String]
    # @return [String]
    def absolute_key(key, path, calling_method)
      if key.start_with?('.')
        if keys_relative_to_calling_method?(path)
          absolutize_key(key, path, config[:relative_roots], calling_method)
        else
          absolutize_key(key, path, config[:relative_roots])
        end
      else
        key
      end
    end


    # Extract a hash pair with a given literal key.
    #
    # @param node [AST::Node] a node of type `:hash`.
    # @param key [String] node key as a string (indifferent symbol-string matching).
    # @return [AST::Node, nil] a node of type `:pair` or nil.
    def extract_hash_pair(node, key)
      node.children.detect { |child|
        next unless child.type == :pair
        key_node = child.children[0]
        %i(sym str).include?(key_node.type) && key_node.children[0].to_s == key
      }
    end

    # If the node type is of `%i(sym str)`, return the symbol / string as a string.
    # Otherwise, if `config[:strict]` is `false` and the type is of `%i(dstr dsym)`,
    # return the source as if it were a string.
    # Otherwise return nil.
    #
    # @param node [Parser::AST::Node]
    # @return [String, nil]
    def extract_string(node)
      if %i(sym str).include?(node.type)
        node.children[0].to_s
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

    def keys_relative_to_calling_method?(path)
      /controllers|mailers/.match(path)
    end

    # @param range [Parser::Source::Range]
    # @param default_arg_node [Parser::Source::Range]
    # @return [Results::Occurrence]
    def range_to_occurrence(range, default_arg_node: nil)
      Results::Occurrence.new(
          path:     range.source_buffer.name,
          pos:      range.begin_pos,
          line_num: range.line,
          line_pos: range.column,
          line:     range.source_line)
    end
  end
end
