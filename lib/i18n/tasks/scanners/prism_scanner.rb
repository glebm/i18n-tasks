# frozen_string_literal: true

require_relative 'file_scanner'
require_relative 'ruby_ast_scanner'

module I18n::Tasks::Scanners
  class PrismScanner < FileScanner
    MAGIC_COMMENT_SKIP_PRISM = 'i18n-tasks-skip-prism'

    def initialize(**args)
      unless VISITOR
        warn(
          'Please make sure `prism` is available to use this feature. Fallback to Ruby AST Scanner.'
        )
      end
      super

      @fallback = RubyAstScanner.new(**args)
    end

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      return @fallback.send(:scan_file, path) if VISITOR.nil?

      process_results(path, PARSER.parse_file(path))
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise(
        ::I18n::Tasks::CommandError.new(
          e,
          "Error scanning #{path}: #{e.message}"
        )
      )
    end

    # Need to have method that can be overridden to be able to test it
    def process_results(path, parse_results)
      parsed = parse_results.value
      comments = parse_results.comments

      return @fallback.send(:scan_file, path) if skip_prism_comment?(comments)

      rails = if config[:prism_visitor].blank?
                true
              else
                config[:prism_visitor] != 'ruby'
              end

      visitor = VISITOR.new(comments: comments, rails: rails)
      parsed.accept(visitor)

      occurrences = []
      visitor.process.each do |translation_call|
        result = translation_call.occurrences(path)
        occurrences << result if result
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

    # This block handles adding a fallback if the `prism` gem is not available.
    begin
      require 'prism'
      require_relative 'prism_scanners/visitor'
      PARSER = Prism
      VISITOR = I18n::Tasks::Scanners::PrismScanners::Visitor
    rescue LoadError
      PARSER = nil
      VISITOR = nil
    end
  end
end
