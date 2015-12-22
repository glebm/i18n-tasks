require 'strscan'

module I18n::Tasks::KeyPatternMatching
  extend self
  MATCH_NOTHING = /\z\A/.freeze

  # one regex to match any
  def compile_patterns_re(key_patterns)
    if key_patterns.blank?
      # match nothing
      MATCH_NOTHING
    else
      /(?:#{ key_patterns.map { |p| compile_key_pattern p } * '|'.freeze })/m
    end
  end

  # convert pattern to regex
  # In patterns:
  #      *     is like .* in regexs
  #      :     matches a single key
  #   { a, b.c } match any in set, can use : and *, match is captured
  def compile_key_pattern(key_pattern)
    return key_pattern if key_pattern.is_a?(Regexp)
    /\A#{key_pattern_re_body(key_pattern)}\z/
  end

  def key_pattern_re_body(key_pattern)
    key_pattern.
        gsub(/\./, '\.'.freeze).
        gsub(/\*/, '.*'.freeze).
        gsub(/:/, '(?<=^|\.)[^.]+?(?=\.|$)'.freeze).
        gsub(/\{(.*?)}/) { "(#{$1.strip.gsub /\s*,\s*/, '|'.freeze})" }
  end

  def key_match_pattern(k, replacement: ':'.freeze)
    @key_match_pattern ||= {}
    @key_match_pattern[k] ||= begin
      "#{replace_key_interpolations(k, replacement)}#{replacement if k.end_with?('.'.freeze)}"
    end
  end

  # @return true if the key looks like an expression
  KEY_INTERPOLATION_RE = /\#{/.freeze
  def key_expression?(k)
    @key_is_expr ||= {}
    if @key_is_expr[k].nil?
      @key_is_expr[k] = (k =~ KEY_INTERPOLATION_RE || k.end_with?('.'.freeze))
    end
    @key_is_expr[k]
  end

  private

  # Replace interpolations.
  # @param key [String]
  # @param replacement [String]
  # @return [String]
  def replace_key_interpolations(key, replacement)
    scanner = StringScanner.new(key)
    braces = []
    result = []
    while (match_until = scanner.scan_until(/(?:#?\{|})/.freeze) )
      if scanner.matched == '#{'.freeze
        braces << scanner.matched
        result << match_until[0..-3] if braces.length == 1
      elsif scanner.matched == '}'
        prev_brace = braces.pop
        result << replacement if braces.empty? && prev_brace == '#{'.freeze
      else
        braces << '{'.freeze
      end
    end
    result << key[scanner.pos..-1] unless scanner.eos?
    result.join
  end
end
