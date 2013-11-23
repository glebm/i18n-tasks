module I18n::Tasks::UntranslatedKeys
  # Get all the missing translations as an array of missing keys as hashes with the following options:
  # :locale
  # :key
  # :type — :blank, :missing, or :eq_base
  # :base_value — translation value in base locale if one is present
  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def untranslated_keys
    other_locales = locales - [base_locale]
    sort_keys keys_missing_base_value + other_locales.map { |locale| keys_missing_translation(locale) }.flatten(1)
  end
end