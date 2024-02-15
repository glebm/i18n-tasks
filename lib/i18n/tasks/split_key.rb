# frozen_string_literal: true

module I18n
  module Tasks
    module SplitKey
      module_function

      PARENTHESIS_PAIRS = %w({} [] () <>).freeze
      START_KEYS = PARENTHESIS_PAIRS.to_set { |pair| pair[0] }.freeze
      END_KEYS = PARENTHESIS_PAIRS.to_h { |pair| [pair[0], pair[1]] }.freeze
      private_constant :PARENTHESIS_PAIRS, :START_KEYS, :END_KEYS

      # split a key by dots (.)
      # dots inside braces or parenthesis are not split on
      #
      # split_key 'a.b'      # => ['a', 'b']
      # split_key 'a.#{b.c}' # => ['a', '#{b.c}']
      # split_key 'a.b.c', 2 # => ['a', 'b.c']
      def split_key(key, max = Float::INFINITY)
        return [key] if max == 1

        parts = []
        current_parenthesis_end_char = nil
        part = ''
        key.each_char.with_index do |char, index|
          if current_parenthesis_end_char
            part += char
            current_parenthesis_end_char = nil if char == current_parenthesis_end_char
          elsif START_KEYS.include?(char)
            part += char
            current_parenthesis_end_char = END_KEYS[char]
          elsif char == '.'
            parts << part
            if parts.size + 1 == max
              remaining = key[(index + 1)..]
              parts << remaining unless remaining.empty?
              return parts
            end
            part = ''
          else
            part += char
          end
        end

        return parts if part.empty?

        current_parenthesis_end_char ? parts.concat(part.split('.')) : parts << part
      end

      def last_key_part(key)
        split_key(key).last
      end
    end
  end
end
