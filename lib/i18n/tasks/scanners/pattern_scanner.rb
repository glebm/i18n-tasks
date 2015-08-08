require 'i18n/tasks/scanners/scanner'
require 'i18n/tasks/scanners/relative_keys'

module I18n::Tasks::Scanners
  # Scan for I18n.t usages using a simple regular expression.
  class PatternScanner < Scanner
    include RelativeKeys

    attr_reader :config

    def initialize(
        config: {},
        file_finder_provider: Files::CachingFileFinderProvider.new,
        file_reader: Files::CachingFileReader.new)
      @config      = config
      @file_reader = file_reader

      @file_finder      = file_finder_provider.get(**config.slice(:paths, :include, :exclude))
      @pattern          = config[:pattern].present? ? Regexp.new(config[:pattern]) : default_pattern
      @ignore_lines_res = (config[:ignore_lines] || []).inject({}) { |h, (ext, re)| h.update(ext => Regexp.new(re)) }
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
      keys = []
      text = read_file(path)
      text.scan(@pattern) do |match|
        src_pos  = Regexp.last_match.offset(0).first
        location = src_location(path, text, src_pos)
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

    # Read a file. Reads of the same path are cached
    #
    # @param path [String]
    # @return [String] file contents
    def read_file(path)
      @file_reader.read_file(path)
    end

    # @param [MatchData] match
    # @param [String] path
    # @return [String] full absolute key name
    def match_to_key(match, path, location)
      absolute_key(strip_literal(match[0]), path, location)
    end

    def exclude_line?(line, path)
      re = @ignore_lines_res[File.extname(path)[1..-1]]
      re && re =~ line
    end

    def absolute_key(key, path, location)
      if key.start_with?('.'.freeze)
        if controller_file?(path) || mailer_file?(path)
          absolutize_key(key, path, config[:relative_roots], closest_method(location))
        else
          absolutize_key(key, path, config[:relative_roots])
        end
      else
        key
      end
    end

    # @param path [String]
    # @param text [String] contents of the file at the path.
    # @param src_pos [Fixnum] position just before the beginning of the match.
    # @return [Results::Occurrence]
    def src_location(path, text, src_pos)
      line_begin = text.rindex(/^/, src_pos - 1)
      line_end   = text.index(/.(?=\r?\n|$)/, src_pos)
      Results::Occurrence.new(
          path:     path,
          pos:      src_pos,
          line_num: text[0..src_pos].count("\n".freeze) + 1,
          line_pos: src_pos - line_begin + 1,
          line:     text[line_begin..line_end])
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

    QUOTES = ["'".freeze, '"'.freeze].freeze
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

    def controller_file?(path)
      /controllers/.match(path)
    end

    def mailer_file?(path)
      /mailers/.match(path)
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
