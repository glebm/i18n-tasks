module I18n::Tasks::PluralKeys
  PLURAL_KEY_RE = /\.(?:zero|one|two|few|many|other)$/

  # @param [String] key i18n key
  # @param [String] locale to pull key data from
  # @return the base form if the key is a specific plural form (e.g. apple for apple.many), and the key as passed otherwise
  def depluralize_key(key, locale = base_locale)
    return key if key !~ PLURAL_KEY_RE
    node = node(key, locale)
    nodes = node.try(:siblings).presence || (locale != base_locale && node(key, base_locale).try(:siblings))
    if nodes && nodes.all? { |x| x.leaf? && ".#{x.key}" =~ PLURAL_KEY_RE }
      key.split('.')[0..-2] * '.'
    else
      key
    end
  end
end
