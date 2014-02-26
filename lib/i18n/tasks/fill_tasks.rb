module I18n::Tasks::FillTasks
  def add_missing!(opts = {})
    locale = opts[:locale] || base_locale
    value  = opts[:value]
    normalize_store! locale
    set_blank_values! locale do |keys|
      keys.map { |key|
        value || key.split('.').last.to_s.humanize
      }
    end
  end

  def fill_with_value!(opts = {})
    locales = non_base_locales opts[:locales]
    value   = opts[:value] || ''
    add_missing! base_locale, value
    normalize_store! locales
    locales.each do |locale|
      add_missing! locale, value
    end
  end

  def fill_with_google_translate!(opts = {})
    locales = non_base_locales opts[:locales]
    normalize_store! base_locale
    normalize_store! locales
    locales.each do |locale|
      blank_keys = keys_missing_from_locale(locale).key_names.select { |k|
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

  def fill_with_base_value!(opts = {})
    locales = non_base_locales opts[:locales]
    normalize_store! base_locale
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
    blank_keys   = keys_missing_from_locale(locale).key_names
    list         = blank_keys.zip fill_with.call(blank_keys)
    data[locale] = data[locale].deep_merge(list_to_tree(list))
  end
end
