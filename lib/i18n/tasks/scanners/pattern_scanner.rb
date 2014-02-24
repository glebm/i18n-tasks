require 'i18n/tasks/scanners/base_scanner'

module I18n::Tasks::Scanners
  # Scans for I18n.t usages
  #
  class PatternScanner < BaseScanner
    LITERAL_RE      = /:?".+?"|:?'.+?'|:\w+/
    DEFAULT_PATTERN = /\bt(?:ranslate)?[( ]\s*(#{LITERAL_RE})/

    # Extract i18n keys from file based on the pattern which must capture the key literal.
    # @return [String] keys found in file
    def scan_file(path, text = read_file(path))
      keys = []
      text.scan(pattern) do |match|
        src_pos = Regexp.last_match.offset(0).first
        key     = extract_key_from_match(match, path)
        next unless valid_key?(key)
        keys << ::I18n::Tasks::Key.new(key, usage_context(text, src_pos))
      end
      keys
    end

    protected

    def pattern
      @pattern ||= config[:pattern].present? ? Regexp.new(config[:pattern]) : DEFAULT_PATTERN
    end
  end
end
