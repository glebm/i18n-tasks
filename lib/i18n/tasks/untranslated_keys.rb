module I18n::Tasks::UntranslatedKeys
  # Get all the missing translations as an array of missing keys as hashes with the following options:
  # :locale
  # :key
  # :type — :blank, :missing, or :eq_base
  # :base_value — translation value in base locale if one is present
  # @param [Array] locales - non base locales for which to return missing keys (base locale always included)
  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def untranslated_keys(locales = nil)
    locales ||= non_base_locales
    sort_key_infos(keys_not_in_base_info + keys_eq_base_info(locales) + keys_blank_in_locale_info(locales))
  end

  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def keys_not_in_base_info
    sort_key_infos keys_to_info(keys_not_in_base, locale: base_locale, type: :none)
  end

  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def keys_eq_base_info(locales)
    sort_key_infos locales.inject([]) { |result, locale|
      result + keys_to_info(keys_eq_base(locale), locale: locale, type: :eq_base)
    }
  end

  # @return [Array<Hash{Symbol => String,Symbol,nil}>]
  def keys_blank_in_locale_info(locales)
    sort_key_infos locales.inject([]) { |result, locale|
      result + keys_to_info(keys_blank_in_locale(locale), locale: locale, type: :blank)
    }
  end

  # sort first by locale, then by type
  # @return Array{Hash}
  def sort_key_infos(keys)
    keys.sort { |a, b|
      by = [:locale, :type, :key].detect { |by| a[by] != b[by] }
      a[by] <=> b[by]
    }
  end

  protected

  # convert the keys to a list of hashes with {key, base_value, *info}
  def keys_to_info(keys, info = {})
    keys.map { |key| {key: key, base_value: t(base_locale, key)}.merge(info) }
  end
end