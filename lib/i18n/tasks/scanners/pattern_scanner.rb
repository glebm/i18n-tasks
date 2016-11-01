# frozen_string_literal: true
require 'i18n/tasks/scanners/file_scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/occurrence_from_position'
require 'i18n/tasks/scanners/ruby_key_literals'

module I18n::Tasks::Scanners
  # Scan for I18n.t usages using a simple regular expression.
  class PatternScanner < FileScanner
    include RelativeKeys
    include OccurrenceFromPosition
    include RubyKeyLiterals

    def initialize(**args)
      super
      @pattern          = config[:pattern].present? ? Regexp.new(config[:pattern]) : default_pattern
      @ignore_lines_res = (config[:ignore_lines] || []).inject({}) { |h, (ext, re)| h.update(ext.to_s => Regexp.new(re)) }
    end

    protected

    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [Array<[key, Results::Occurrence]>] each occurrence found in the file
    def scan_file(path)
      keys = []
      text = read_file(path)
      text.scan(@pattern) do |match|
        src_pos  = Regexp.last_match.offset(0).first
        location = occurrence_from_position(path, text, src_pos, raw_key: strip_literal(match[0]))
        next if exclude_line?(location.line, path)
        key = match_to_key(match, path, location)
        next unless key
        key = key + ':'.freeze if key.end_with?('.'.freeze)
        next unless valid_key?(key)
        keys << [key, location]
      end
      keys
    rescue Exception => e
      raise ::I18n::Tasks::CommandError.new(e, "Error scanning #{path}: #{e.message}")
    end

    # @param [MatchData] match
    # @param [String] path
    # @return [String] full absolute key name
    def match_to_key(match, path, location)
      absolute_key(strip_literal(match[0]), path,
                   calling_method: -> { closest_method(location) if key_relative_to_method?(path) })
    end

    def exclude_line?(line, path)
      re = @ignore_lines_res[File.extname(path)[1..-1]]
      re && re =~ line
    end

    VALID_KEY_RE_DYNAMIC = /^(#{VALID_KEY_CHARS}|[:\#{@}\[\]])+$/

    def valid_key?(key)
      if @config[:strict]
        super(key)
      else
        key =~ VALID_KEY_RE_DYNAMIC
      end
    end

    def key_relative_to_method?(path)
      /controllers|mailers/ =~ path
    end

    def closest_method(occurrence)
      method = File.readlines(occurrence.path, encoding: 'UTF-8'.freeze).
          first(occurrence.line_num - 1).reverse_each.find { |x| x =~ /\bdef\b/ }
      method && method.strip.sub(/^def\s*/, '').sub(/[\(\s;].*$/, '')
    end

    def translate_call_re
      /(?<=^|[^\w'\-.]|[^\w'\-]I18n\.|I18n\.)t(?:ranslate)?/
    end

    def default_pattern
      # capture only the first argument
      /
      #{translate_call_re} [\( ] \s* (?# fn call begin )
      (#{literal_re})                (?# capture the first argument)
      /x
    end
  end
end
