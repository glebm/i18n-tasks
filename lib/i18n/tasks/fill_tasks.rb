module I18n::Tasks::FillTasks
  def add_missing!(opts = {})
    locale = opts[:locale] || base_locale
    value  = opts[:value]
    normalize_store! locale
    if locale != base_locale
      add_missing! locale: base_locale, value: value
    end

    keys   = keys_missing_from_locale(locale).key_names
    values = value.respond_to?(:call) ? keys.map { |key| value.call(key) } : [value] * keys.size
    data[locale] = data[locale].deep_merge(list_to_tree keys.zip(values))
  end

  def fill_with_value!(opts = {})
    value = opts[:value] || ''
    ([base_locale] + non_base_locales(opts[:locales])).each do |locale|
      add_missing! locale: locale, value: value
    end
  end

  def fill_with_google_translate!(opts = {})
    locales = non_base_locales opts[:locales]
    normalize_store! locales
    locales.each do |locale|
      keys = keys_missing_from_locale(locale).key_names.select { |k|
        (base_value = t(k)).present? && base_value.is_a?(String)
      }
      if keys.present?
        data[locale] = data[locale].deep_merge(
          list_to_tree google_translate(keys.zip(keys.map { |k| t(k) }), to: locale, from: base_locale)
        )
      end
    end
  end

  def fill_with_base_value!(opts = {})
    base_value = proc { |key| t(key) }
    non_base_locales(opts[:locales]).each do |locale|
      add_missing! locale: locale, value: base_value
    end
  end
end
