module I18n::Tasks::MissingKeys
  # @return Array missing keys, i.e. key that are in the code but are not in the base locale data
  def keys_not_in_base
    find_source_keys.reject { |key|
      key_value?(key, base_locale) || pattern_key?(key) || ignore_key?(key, :missing)
    }
  end

  # @return Array keys missing (nil or blank?) in locale but present in base
  def keys_blank_in_locale(locale)
    traverse_map_if data[base_locale] do |key, base_value|
      key if !ignore_key?(key, :missing) && !key_value?(key, locale) && !key_value?(depluralize_key(key), locale)
    end
  end

  # @return Array keys missing value (but present in base)
  def keys_eq_base(locale)
    traverse_map_if data[base_locale] do |key, base_value|
      key if base_value == t(locale, key) && !ignore_key?(key, :eq_base, locale)
    end
  end

end