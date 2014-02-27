module I18n::Tasks::PluralKeys
  PLURAL_KEY_RE = /\.(?:zero|one|two|few|many|other)$/

  # @param [String] key i18n key
  # @param [String] locale to pull key data from
  # @return the base form if the key is a specific plural form (e.g. apple for apple.many), and the key as passed otherwise
  def depluralize_key(locale = base_locale, key)
    return key if key !~ PLURAL_KEY_RE || t(key, locale).is_a?(Hash)
    parent_key      = key.split('.')[0..-2] * '.'
    plural_versions = t(parent_key, locale)
    if plural_versions.is_a?(Hash) && plural_versions.all? { |k, v| ".#{k}" =~ PLURAL_KEY_RE && !v.is_a?(Hash) }
      parent_key
    else
      key
    end
  end
end
