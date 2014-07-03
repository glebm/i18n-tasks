# coding: utf-8
require 'i18n/tasks/scanners/base_scanner'

module I18n::Tasks::Scanners
  # Scans for I18n.t usages
  #
  class PatternScanner < BaseScanner
    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [Array<Key>] keys found in file
    def scan_file(path, text = read_file(path))
      keys = []
      text.scan(pattern) do |match|
        src_pos = Regexp.last_match.offset(0).first
        key     = match_to_key(match, path)
        next unless valid_key?(key)
        location = src_location(path, text, src_pos)
        unless exclude_line?(location[:line])
          keys << [key, data: location]
        end
      end
      keys
    end

    def default_pattern
      # capture only the first argument
      /
      #{translate_call_re} [\( ] \s* (?# fn call begin )
      (#{literal_re})                (?# capture the first argument)
      /x
    end

    protected

    # Given
    # @param [MatchData] match
    # @param [String] path
    # @return [String] full absolute key name
    def match_to_key(match, path)
      key = strip_literal(match[0])
      key = key + '*' if key.end_with?('.')
      key = absolutize_key(key, path) if path && key.start_with?('.')
      key
    end

    def pattern
      @pattern ||= config[:pattern].present? ? Regexp.new(config[:pattern]) : default_pattern
    end

    def translate_call_re
      /(?<=^|[^\w'\-])t(?:ranslate)?/
    end

    # Match literals:
    # * String: '', "#{}"
    # * Symbol: :sym, :'', :"#{}"
    def literal_re
      /:?".+?"|:?'.+?'|:\w+/
    end
  end
end
