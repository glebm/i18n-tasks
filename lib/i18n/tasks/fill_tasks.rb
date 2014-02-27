module I18n::Tasks::FillTasks
  def fill_missing_value(opts = {})
    update_data locales: opts[:locales],
                keys:    proc { |locale| keys_to_fill(locale) },
                value:   opts[:value] || ''
  end

  def fill_missing_google_translate(opts = {})
    update_data locales: non_base_locales(opts[:locales]),
                keys:    proc { |locale| keys_to_fill(locale).select(&t_proc).select { |k| t(k).is_a?(String) } },
                values:  proc { |keys, locale|
                  google_translate keys.zip(keys.map(&t_proc)), to: locale, from: base_locale
                }
  end

  def fill_missing_base_value(opts = {})
    update_data locales: non_base_locales(opts[:locales]),
                keys:    proc { |locale| keys_to_fill(locale).select(&t_proc) },
                value:   t_proc(base_locale)
  end

  def keys_to_fill(locale)
    keys_missing_from_locale(locale).key_names
  end
end
