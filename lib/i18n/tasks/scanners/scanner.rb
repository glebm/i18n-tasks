module I18n::Tasks::Scanners
  # Describes the API of a scanner.
  #
  # @abstract
  # @since 0.9.0
  class Scanner
    # @abstract
    # @return [Array<KeyOccurrences>] the keys found by this scanner and their occurrences.
    def keys
      raise 'Unimplemented'
    end
  end

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

  # The occurrence of some key in a file.
  #
  # @note This is a value type. Equality and hash code are determined from the attributes.
  class Occurrence
    # @return [String] source path relative to the current working directory.
    attr_reader :path

    # @return [Fixnum] count of characters in the file before the occurrence.
    attr_reader :pos

    # @return [Fixnum] line number of the occurrence, counting from 1.
    attr_reader :line_num

    # @return [Fixnum] position of the start of the occurrence in the line, counting from 1.
    attr_reader :line_pos

    # @return [String] the line of the occurrence, excluding the last LF or CRLF.
    attr_reader :line

    # @param path     [String]
    # @param pos      [Fixnum]
    # @param line_num [Fixnum]
    # @param line_pos [Fixnum]
    # @param line     [String]
    def initialize(path:, pos:, line_num:, line_pos:, line:)
      @path     = path
      @pos      = pos
      @line_num = line_num
      @line_pos = line_pos
      @line     = line
    end

    def inspect
      "Occurrence(#{@path}:#{@line_num}:#{@line_pos})"
    end

    def ==(other)
      other.path == @path && other.pos == @pos && other.line_num == @line_num && other.line == @line
    end

    def eql?(other)
      self == other
    end

    def hash
      [@path, @pos, @line_num, @line_pos, @line].hash
    end
  end
end
