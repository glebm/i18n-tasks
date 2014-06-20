# coding: utf-8
module I18n::Tasks::FillTasks
  def fill_missing_value(opts = {})
    opts = opts.merge(
        keys:  proc { |locale|
          missing_tree(locale).key_names.map { |key| depluralize_key(key, locale) }.uniq
        }
    )
    opts[:value] ||= '' unless opts[:values].present?
    update_data opts
  end

  def fill_missing_google_translate(opts = {})
    from = opts[:from] || base_locale
    opts = opts.merge(
        locales: Array(opts[:locales]) - Array(from),
        keys:    proc { |locale| missing_tree(locale, from).key_names.map(&:to_s) },
        values:  proc { |keys, locale|
          google_translate(keys.zip(keys.map(&t_proc(from))), to: locale, from: from).map(&:last)
        }
    )
    update_data opts
  end
end
