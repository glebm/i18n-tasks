module SplitKey
  extend self

  # split a key taking parenthesis into account
  # split_key 'a.b'      # => ['a', 'b']
  # split_key 'a.#{b.c}' # => ['a', '#{b.c}']
  # split_key 'a.b.c', 2 # => ['a', 'b.c']
  def split_key(key, max = Float::INFINITY)
    parts = []
    nesting = NESTING_CHARS
    counts  = Array.new(NESTING_CHARS.size, 0)
    delim   = '.'.freeze
    buf = []
    key.to_s.chars.each do |char|
      nest_i, nest_inc = nesting[char]
      if nest_i
        counts[nest_i] += nest_inc
        buf << char
      elsif char == delim && parts.length + 1 < max && counts.all?(&:zero?)
        part = buf.join
        buf.clear
        parts << part
        yield part if block_given?
      else
        buf << char
      end
    end
    parts << buf.join unless buf.empty?
    parts
  end

  NESTING_CHARS = %w({} [] ()).inject({}) { |h, s|
    i = h.size / 2
    h[s[0].freeze] = [i, 1].freeze
    h[s[1].freeze] = [i, -1].freeze
    h
  }.freeze
  private_constant :NESTING_CHARS
end
