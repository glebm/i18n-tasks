require 'i18n/tasks/relative_keys'
module I18n::Tasks::Scanners
  class BaseScanner
    include ::I18n::Tasks::RelativeKeys
    include ::I18n::Tasks::KeyPatternMatching
    attr_reader :config, :key_filter, :record_usages

    def initialize(config)
      @config        = config.dup.with_indifferent_access.tap do |conf|
        conf[:paths]   = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude])
      end
      @record_usages = false
    end

    def key_filter=(value)
      @key_filter = value
      @key_filter_pattern = compile_key_pattern(value) if @key_filter
    end

    # @return [Array] found key usages, absolutized and unique
    def keys
      if @record_usages
        keys_with_usages
      else
        @keys ||= traverse_files { |path| scan_file(path, read_file(path)).map(&:key) }.reduce(:+).uniq
      end
    end

    def keys_with_usages
      with_usages do
        traverse_files { |path|
          ::I18n::Tasks::KeyGroup.new(scan_file(path, read_file(path)), src_path: path)
        }.map(&:keys).reduce(:+).group_by(&:key).map { |key, key_usages|
          {key: key, usages: key_usages.map { |usage| usage[:src].merge(path: usage[:src_path]) }}
        }
      end
    end

    def read_file(path)
      result = nil
      File.open(path, 'rb') { |f| result = f.read }
      result
    end

    # @return [String] keys used in file (unimplemented)
    def scan_file(path, *args)
      raise 'Unimplemented'
    end

    # Run given block for every relevant file, according to config
    # @return [Array] Results of block calls
    def traverse_files
      result = []
      Find.find(*config[:paths]) do |path|
        next if File.directory?(path) ||
            config[:include] && !path_fnmatch_any?(path, config[:include]) ||
            path_fnmatch_any?(path, config[:exclude])
        result << yield(path)
      end
      result
    end

    def path_fnmatch_any?(path, globs)
      globs.any? { |glob| File.fnmatch(glob, path) }
    end
    protected :path_fnmatch_any?

    def with_key_filter(key_filter = nil)
      filter_was      = @key_filter
      self.key_filter = key_filter
      result          = yield
      self.key_filter = filter_was
      result
    end

    def with_usages
      was            = @record_usages
      @record_usages = true
      result         = yield
      @record_usages = was
      result
    end

    protected

    def usage_context(text, src_pos)
      return nil unless @record_usages
      line_begin = text.rindex(/^/, src_pos - 1)
      line_end   = text.index(/.(?=\n|$)/, src_pos)
      {src: {
          pos:      src_pos,
          line_num: text[0..src_pos].count("\n") + 1,
          line_pos: src_pos - line_begin + 1,
          line:     text[line_begin..line_end]
      }}
    end

    def extract_key_from_match(match, path)
      key = strip_literal(match[0])
      key = absolutize_key(key, path) if path && key.start_with?('.')
      key
    end

    # remove the leading colon and unwrap quotes from the key match
    def strip_literal(literal)
      key = literal
      key.slice!(0) if ':' == key[0]
      key = key[1..-2] if %w(' ").include?(key[0])
      key
    end

    VALID_KEY_RE = /^[\w.\#{}]+$/

    def valid_key?(key)
      key =~ VALID_KEY_RE && !(@key_filter && @key_filter_pattern !~ key)
    end

    def relative_roots
      config[:relative_roots]
    end

  end
end
