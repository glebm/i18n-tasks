# frozen_string_literal: true

# This module provides a factory class for creating a Ruby parser instance.
# It temporarily disables verbose mode to suppress compatibility warnings
# when loading the "parser/current" library.
#
# Example warning for the release of Ruby 3.4.1:
#   warning: parser/current is loading parser/ruby34, which recognizes
#   3.4.0-compliant syntax, but you are running 3.4.1.
#   Please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
#
# By disabling verbose mode, these warnings are suppressed to provide a cleaner
# output and avoid confusion. The verbose mode is restored after the parser
# instance is created to maintain the original behavior.

module I18n::Tasks::Scanners
  class RubyParserFactory
    def self.create_parser
      prev = $VERBOSE
      $VERBOSE = nil
      require 'parser/current'
      ::Parser::CurrentRuby.new
    ensure
      $VERBOSE = prev
    end
  end
end
