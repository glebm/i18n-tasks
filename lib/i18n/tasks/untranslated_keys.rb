module I18n::Tasks::UntranslatedKeys
  # Get all the missing translations as an array of missing keys as hashes with the following options:
  # :locale
  # :key
  # :type — :blank, :missing, or :eq_base
  # :base_value — translation value in base locale if one is present
  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def untranslated_keys
    keys = keys_missing_from_base.map { |key| {locale: base_locale, key: key, type: :none} } +
        non_base_locales.map { |locale|
          keys_missing_value(locale).map { |key| {locale: locale, key: key, type: :blank, base_value: t(key, base_locale)}} + keys_where_value_eq_base(locale).map { |key|
            {locale: locale, key: key, type: :eq_base, base_value: t(key, base_locale)}
          }
        }.flatten.uniq
    sort_keys keys
  end

  # sort first by locale, then by type
  # @return Array{Hash}
  def sort_keys(keys)
    keys.sort { |a, b|
      (l = a[:locale] <=> b[:locale]).zero? ? a[:type] <=> b[:type] : l
    }
  end
end