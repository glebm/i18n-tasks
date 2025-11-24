# frozen_string_literal: true

require "i18n/tasks/scanners/scanner"

module I18n::Tasks::Scanners
  # Run multiple {Scanner Scanners} and merge their results.
  class ScannerMultiplexer < Scanner
    # @param scanners [Array<Scanner>]
    def initialize(scanners:)
      super()
      @scanners = scanners
    end

    # Collect the results of all the scanners. Occurrences of a key from multiple scanners are merged.
    #
    # @return (see Scanner#keys)
    def keys
      results = @scanners.map(&:keys)
      Results::KeyOccurrences.merge_keys results.flatten(1)
    end
  end
end
