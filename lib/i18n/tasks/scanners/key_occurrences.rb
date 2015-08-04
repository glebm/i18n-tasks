require 'i18n/tasks/scanners/occurence'

module I18n::Tasks::Scanners
  # A scanned key and all its occurrences.
  #
  # @note This is a value type. Equality and hash code are determined from the attributes.
  class KeyOccurrences
    # @return [String] the key.
    attr_reader :key

    # @return [Array<Occurrence>] the key's occurrences.
    attr_reader :occurrences

    def initialize(key:, occurrences:)
      @key         = key
      @occurrences = occurrences
    end

    def ==(other)
      other.key == @key && other.occurrences == @occurrences
    end

    def eql?(other)
      self == other
    end

    def hash
      [@key, @occurrences].hash
    end

    def inspect
      "KeyOccurrences(#{key.inspect}, [#{occurrences.map(&:inspect).join(', ')}])"
    end
  end
end
