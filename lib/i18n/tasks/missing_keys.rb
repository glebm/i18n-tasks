module I18n::Tasks::MissingKeys
  # missing keys, i.e. key that are in the code but are not in the base locale data
  # @return Array{Hash}
  def keys_missing_base_value
    find_source_keys.reject { |key|
      key_value?(key, base_locale) || pattern_key?(key) || ignore_key?(key, :missing)
    }.map { |key| {locale: base_locale, type: :none, key: key} }
  end

  # present in base locale, but untranslated in another locale
  # @return Array{Hash}
  def keys_missing_translation(locale)
    trn = data[locale]
    r   = []
    traverse data[base_locale] do |key, base_value|
      value_in_locale = t(trn, key)
      if value_in_locale.blank? && !ignore_key?(key, :missing)
        r << {locale: locale, key: key, type: :blank, base_value: base_value}
      elsif value_in_locale == base_value && !ignore_key?(key, :eq_base, locale)
        r << {locale: locale, key: key, type: :eq_base, base_value: base_value}
      end
    end
    r
  end

  # sort first by locale, then by type
  # @return Array{Hash}
  def sort_keys(keys)
    keys.sort { |a, b|
      (l = a[:locale] <=> b[:locale]).zero? ? a[:type] <=> b[:type] : l
    }
  end
end