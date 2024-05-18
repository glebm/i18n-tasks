# frozen_string_literal: true

require_relative 'file_scanner'
require_relative 'ruby_ast_scanner'

module I18n::Tasks::Scanners
  class PrismScanner < FileScanner
    def initialize(**args)
      unless RAILS_VISITOR || RUBY_VISITOR
        warn(
          'Please make sure `prism` is available to use this feature. Fallback to Ruby AST Scanner.'
        )
      end
      super

      @visitor_class = config[:prism_visitor] == 'ruby' ? RUBY_VISITOR : RAILS_VISITOR
      @fallback = RubyAstScanner.new(**args)
    end

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      return @fallback.send(:scan_file, path) if @visitor_class.nil?

      process_prism_parse_result(
        path,
        PARSER.parse_file(path).value,
        PARSER.parse_file_comments(path)
      )
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise(
        ::I18n::Tasks::CommandError.new(
          e,
          "Error scanning #{path}: #{e.message}"
        )
      )
    end

    def process_prism_parse_result(path, parsed, comments = nil)
      return @fallback.send(:scan_file, path) if RUBY_VISITOR.skip_prism_comment?(comments)

      visitor = @visitor_class.new(comments: comments)
      nodes = parsed.accept(visitor)

      nodes
        .filter_map do |node|
          next node.occurrences(path) if node.is_a?(I18n::Tasks::Scanners::PrismScanners::TranslationNode)
          next unless node.respond_to?(:translation_nodes)

          node.translation_nodes.flat_map { |n| n.occurrences(path) }
        end
        .flatten(1)
    end

    # This block handles adding a fallback if the `prism` gem is not available.
    begin
      require 'prism'
      require_relative 'prism_scanners/rails_visitor'
      require_relative 'prism_scanners/visitor'
      PARSER = Prism
      RUBY_VISITOR = I18n::Tasks::Scanners::PrismScanners::Visitor
      RAILS_VISITOR = I18n::Tasks::Scanners::PrismScanners::RailsVisitor
    rescue LoadError
      PARSER = nil
      RUBY_VISITOR, RAILS_VISITOR = nil
    end
  end
end
