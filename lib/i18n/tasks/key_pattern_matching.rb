module I18n::Tasks::KeyPatternMatching
  # one regex to match any
  def compile_patterns_re(key_patterns)
    /(?:#{ key_patterns.map { |p| key_pattern_to_re p } * '|' })/m
  end

  # convert key.* to key\..*
  def key_pattern_to_re(key_pattern)
    if key_pattern.end_with? '.'
      $stderr.puts %Q(i18n-tasks: Deprecated "#{key_pattern}", please change to "#{key_pattern}".)
      key_pattern += '*'
    end
    /#{key_pattern.
        gsub(/\./, '\.').
        gsub(/\*/, '.*')}/
  end

  # compile prefix matching Regexp from the list of prefixes
  # @return [Regexp] regexp matching any of the prefixes
  def compile_start_with_re(prefixes)
    if prefixes.blank?
      /\Z\A/ # match nothing
    else
      /^(?:#{prefixes.map { |p| Regexp.escape(p) }.join('|')})/
    end
  end
end