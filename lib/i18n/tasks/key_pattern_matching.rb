module I18n::Tasks::KeyPatternMatching
  MATCH_NOTHING = /\z\A/

  # one regex to match any
  def compile_patterns_re(key_patterns)
    if key_patterns.blank?
      # match nothing
      MATCH_NOTHING
    else
      /(?:#{ key_patterns.map { |p| compile_key_pattern p } * '|' })/m
    end
  end

  # convert pattern to regex
  # In patterns:
  #      *     is like .* in regexs
  #      :     matches a single key
  #   {a, b.c} match any in set, can use : and *, match is captured
  def compile_key_pattern(key_pattern)
    return key_pattern if key_pattern.is_a?(Regexp)
    /\A#{key_pattern_re_body(key_pattern)}\z/
  end

  def key_pattern_re_body(key_pattern)
    key_pattern.
        gsub(/\./, '\.').
        gsub(/\*/, '.*').
        gsub(/:/, '(?<=^|\.)[^.]+?(?=\.|$)').
        gsub(/\{(.*?)}/) { "(#{$1.strip.gsub /\s*,\s*/, '|'})" }
  end
end
