module I18n::Tasks::FillTasks
  def add_missing!(locale = base_locale, placeholder = nil)
    normalize_store! locale
    set_blank_values! locale, locale == base_locale do |keys|
      keys.map { |key|
        placeholder || key.split('.').last.to_s.humanize
      }
    end
  end

  def fill_with_blanks!(locales = nil)
    locales = non_base_locales(locales)
    add_missing! base_locale, ''
    normalize_store! locales
    locales.each do |locale|
      add_missing! locale, ''
    end
  end

  def fill_with_google_translate!(locales = nil)
    normalize_store! base_locale
    locales = non_base_locales(locales)
    normalize_store! locales
    locales.each do |locale|
      set_blank_values! locale do |blank_keys|
        google_translate blank_keys.map { |k| t(k) }, to: locale, from: base_locale
      end
    end
  end

  def fill_with_base_values!(locales = nil)
    normalize_store! base_locale
    locales = non_base_locales(locales)
    normalize_store! locales
    locales.each do |locale|
      set_blank_values! locale do |blank_keys|
        blank_keys.map { |k| t(k) }
      end
    end
  end

  # fill blank values with values from passed block
  # @param [String] locale
  # @param [true, false] include_missing Include keys present in source but missing from base locale
  def set_blank_values!(locale = base_locale, include_missing = (locale == base_locale), &fill_with)
    blank_keys = traverse_map_if(data[base_locale]) { |key, value|
      key if !key_value?(key, locale) && !ignore_key?(key, :missing)
    }
    blank_keys += keys_missing_from_base if include_missing

    list         = blank_keys.uniq.zip fill_with.call(blank_keys)
    data[locale] = data[locale].deep_merge(list_to_tree(list))
  end
end