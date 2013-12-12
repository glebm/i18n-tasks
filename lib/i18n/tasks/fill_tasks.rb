module I18n::Tasks::FillTasks
  def add_missing!(locale = base_locale, placeholder = nil)
    normalize_store! locale
    set_blank_values! locale do |keys|
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
      blank_keys = find_blank_keys(locale).select { |k|
        tr = t(k)
        tr.present? && tr.is_a?(String)
      }
      if blank_keys.present?
        data[locale] = data[locale].deep_merge(
          list_to_tree google_translate(blank_keys.zip(blank_keys.map { |k| t(k) }), to: locale, from: base_locale)
        )
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
  def set_blank_values!(locale = base_locale, &fill_with)
    blank_keys   = find_blank_keys locale
    list         = blank_keys.zip fill_with.call(blank_keys)
    data[locale] = data[locale].deep_merge(list_to_tree(list))
  end


  def find_blank_keys(locale, include_missing = (locale == base_locale))
    blank_keys = traverse_map_if(data[base_locale]) { |key, value|
      key if !key_value?(key, locale) && !ignore_key?(key, :missing)
    }
    blank_keys += keys_not_in_base if include_missing
    blank_keys.uniq
  end
end
