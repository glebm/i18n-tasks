# Scans for I18n.t usages
require 'i18n/tasks/scanners/base_scanner'
module I18n::Tasks::Scanners
  class PatternScanner < BaseScanner
    LITERAL_RE = /:?".+?"|:?'.+?'|:\w+/
    DEFAULT_PATTERN = /\bt(?:ranslate)?[( ]\s*(#{LITERAL_RE})/

    # Extract i18n keys from file based on the pattern. The pattern must capture key literal.
    # @return [String] keys found in file
    def scan_file(path)
      keys = []
      File.open(path, 'rb') do |f|
        f.read.scan(pattern) do |match|
          key = extract_key_from_match(match, path)
          keys << key if valid_key?(key)
        end
      end
      keys
    end

    protected
    def pattern
      @pattern ||= config[:pattern].present? ? Regexp.new(config[:pattern]) : DEFAULT_PATTERN
    end
  end
end
