# coding: utf-8
require 'i18n/tasks/scanners/base_scanner'

module I18n::Tasks::Scanners
  # Scans for I18n.t usages
  #
  class PatternScanner < BaseScanner
    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [Array<Key>] keys found in file
    def scan_file(path, opts = {})
      keys = []
      strict = !!opts[:strict]
      text = opts[:text] || read_file(path)
      text.scan(pattern) do |match|
        src_pos = Regexp.last_match.offset(0).first
        location = src_location(path, text, src_pos)
        next if exclude_line?(location[:line], path)
        key = match_to_key(match, path, location)
        next unless key
        key = key + ':' if key.end_with?('.')
        next unless valid_key?(key, strict)
        keys << [key, data: location]
      end
      keys
    rescue Exception => e
      raise ::I18n::Tasks::CommandError.new("Error scanning #{path}: #{e.message}")
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
    def match_to_key(match, path, location)
      key = strip_literal(match[0])
      absolute_key(key, path, location)
    end

    def absolute_key(key, path, location)
      if key.start_with?('.')
        if controller_file?(path) || mailer_file?(path)
          absolutize_key(key, path, relative_roots, closest_method(location))
        else
          absolutize_key(key, path)
        end
      else
        key
      end
    end

    def controller_file?(path)
      /controllers/.match(path)
    end

    def mailer_file?(path)
      /mailers/.match(path)
    end

    def closest_method(location)
      method = File.readlines(location[:src_path], encoding: 'UTF-8').first(location[:line_num] - 1).reverse_each.find { |x| x=~ /\bdef\b/ }
      method &&= method.strip.sub(/^def\s*/, '').sub(/[\(\s;].*$/, '')
      method
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
