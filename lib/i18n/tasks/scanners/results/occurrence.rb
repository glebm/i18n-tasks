module I18n::Tasks
  module Scanners
    module Results
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

        # @return [String, nil] the value of the `default:` argument of the translate call.
        attr_reader :default_arg

        # @param path        [String]
        # @param pos         [Fixnum]
        # @param line_num    [Fixnum]
        # @param line_pos    [Fixnum]
        # @param line        [String]
        # @param default_arg [String, nil]
        def initialize(path:, pos:, line_num:, line_pos:, line:, default_arg: nil)
          @path        = path
          @pos         = pos
          @line_num    = line_num
          @line_pos    = line_pos
          @line        = line
          @default_arg = default_arg
        end

        def inspect
          "Occurrence(#{@path}:#{@line_num}:#{@line_pos}:(#{@pos})"
        end

        def ==(other)
          other.path == @path && other.pos == @pos && other.line_num == @line_num && other.line == @line
        end

        def eql?(other)
          self == other
        end

        def hash
          [@path, @pos, @line_num, @line_pos, @line, @default_arg].hash
        end
      end
    end
  end
end
