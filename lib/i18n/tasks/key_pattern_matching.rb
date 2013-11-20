module I18n::Tasks::KeyPatternMatching
  MATCH_NOTHING = /\z\A/

  # one regex to match any
  def compile_patterns_re(key_patterns)
    if key_patterns.blank?
      # match nothing
      MATCH_NOTHING
    else
      /(?:#{ key_patterns.map { |p| key_pattern_to_re p } * '|' })/m
    end
  end

  # convert key.* to key\..*
  def key_pattern_to_re(key_pattern)
    if key_pattern.end_with? '.'
      warn_deprecated %Q(please change pattern "#{key_pattern}" to "#{key_pattern += '*'}" in config/i18n-tasks.yml)
    end
    /^#{key_pattern.
        gsub(/\./, '\.').
        gsub(/\*/, '.*')}$/
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