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
    /^#{key_pattern.
        gsub(/\./, '\.').
        gsub(/\*/, '.*').
        gsub(/:/, '(?<=^|\.)[^.]+?(?=\.|$)').
        gsub(/\{(.*?)}/) { "(#{$1.strip.gsub /\s*,\s*/, '|'})" }
    }$/
  end

  # @return [Array<String>] keys sans passed patterns
  def exclude_patterns(keys, patterns)
    pattern_re = compile_patterns_re patterns.select { |p| p.end_with?('.') }
    (keys - patterns).reject { |k| k =~ pattern_re }
  end

  # compile prefix matching Regexp from the list of prefixes
  # @return [Regexp] regexp matching any of the prefixes
  def compile_start_with_re(prefixes)
    if prefixes.blank?
      MATCH_NOTHING # match nothing
    else
      /^(?:#{prefixes.map { |p| Regexp.escape(p) }.join('|')})/
    end
  end
end
