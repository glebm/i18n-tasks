require 'i18n/tasks/scanners/file_scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/occurrence_from_position'

module I18n::Tasks::Scanners
  # Scan for I18n.t usages using a simple regular expression.
  class PatternScanner < FileScanner
    include RelativeKeys
    include OccurrenceFromPosition

    def initialize(**args)
      super
      @pattern          = config[:pattern].present? ? Regexp.new(config[:pattern]) : default_pattern
      @ignore_lines_res = (config[:ignore_lines] || []).inject({}) { |h, (ext, re)| h.update(ext => Regexp.new(re)) }
    end

    protected

    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(path)
      keys = []
      text = read_file(path)
      text.scan(@pattern) do |match|
        src_pos  = Regexp.last_match.offset(0).first
        location = occurrence_from_position(path, text, src_pos)
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

    # remove the leading colon and unwrap quotes from the key match
    # @param literal [String] e.g: "key", 'key', or :key.
    # @return [String] key
    def strip_literal(literal)
      key = literal
      key = key[1..-1] if ':'.freeze == key[0]
      key = key[1..-2] if QUOTES.include?(key[0])
      key
    end

    QUOTES              = ["'".freeze, '"'.freeze].freeze
    VALID_KEY_CHARS     = /(?:[[:word:]]|[-.?!;À-ž])/
    VALID_KEY_RE_STRICT = /^#{VALID_KEY_CHARS}+$/
    VALID_KEY_RE        = /^(#{VALID_KEY_CHARS}|[:\#{@}\[\]])+$/

    def valid_key?(key)
      if @config[:strict]
        key =~ VALID_KEY_RE_STRICT && !key.end_with?('.')
      else
        key =~ VALID_KEY_RE
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
      /(?<=^|[^\w'\-])t(?:ranslate)?/
    end

    # Match literals:
    # * String: '', "#{}"
    # * Symbol: :sym, :'', :"#{}"
    def literal_re
      /:?".+?"|:?'.+?'|:\w+/
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
