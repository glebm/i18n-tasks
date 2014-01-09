require 'i18n/tasks/relative_keys'
module I18n::Tasks::KeyScanners
  class BaseScanner
    include ::I18n::Tasks::RelativeKeys
    attr_reader :config

    def initialize(config)
      @config = config.dup.with_indifferent_access.tap do |conf|
        conf[:paths]   = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude])
      end
    end

    # @return [Array] found key usages, absolutized and unique
    def keys
      @keys ||= traverse_files { |path| scan_file(path) }.flatten.uniq
    end

    # @return [String] keys used in file (unimplemented)
    def scan_file(path)
      raise 'Unimplemented'
    end

    # Run given block for every relevant file, according to config
    # @return [Array] Results of block calls
    def traverse_files
      result = []
      Find.find(*config[:paths]) do |path|
        next if File.directory?(path)
        next if config[:include] and !config[:include].any? { |glob| File.fnmatch(glob, path) }
        next if config[:exclude].any? { |glob| File.fnmatch(glob, path) }
        result << yield(path)
      end
      result
    end

    protected

    def extract_key_from_match(match, path)
      key = strip_literals(match)
      key = absolutize_key(key, path) if path && key.start_with?('.')
      key
    end

    # remove the leading colon and unwrap quotes from the key match
    def strip_literals(match)
      key = match[0]
      key.slice!(0) if ':' == key[0]
      key = key[1..-2] if %w(' ").include?(key[0])
      key
    end

    VALID_KEY_RE = /^[\w.\#{}]+$/

    def valid_key?(key)
      key =~ VALID_KEY_RE
    end

    def relative_roots
      config[:relative_roots]
    end

  end
end
