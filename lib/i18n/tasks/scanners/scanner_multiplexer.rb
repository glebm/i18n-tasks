require 'i18n/tasks/scanners/scanner'

module I18n::Tasks::Scanners
  # Run multiple {Scanner Scanners} and merge their results.
  # @note The scanners are run concurrently. A thread is spawned per each scanner.
  # @since 0.9.0
  class ScannerMultiplexer < Scanner
    # @param scanners [Array<Scanner>]
    def initialize(scanners:)
      @scanners = scanners
    end

    # Collect the results of all the scanners. Occurrences of a key from multiple scanners are merged.
    #
    # @note The scanners are run concurrently. A thread is spawned per each scanner.
    # @return (see Scanner#keys)
    def keys
      collect_results.inject({}) { |results_by_key, key_occurences|
        key_occurences.each do |key_occurrence|
          (results_by_key[key_occurrence.key] ||= []) << key_occurrence.occurrences
        end
        results_by_key
      }.map { |key, all_occurrences|
        occurrences = all_occurrences.flatten(1)
        occurrences.sort_by!(&:path)
        occurrences.uniq!
        KeyOccurrences.new(key: key, occurrences: occurrences)
      }
    end

    private

    # @return Array<Array<KeyOccurrences>>
    def collect_results
      Array.new(@scanners.length).tap do |results|
        @scanners.map.with_index { |scanner, i|
          Thread.start { results[i] = scanner.keys }
        }.each(&:join)
      end
    end
  end
end
