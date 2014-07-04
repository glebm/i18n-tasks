# coding: utf-8
module I18n::Tasks
  module FillTasks
    def fill_missing_value(opts = {})
      value = opts[:value] || ''
      base  = opts[:base_locale] || base_locale
      locales_for_update(opts).each do |locale|
        m = missing_tree(locale, base).keys { |key, node|
          node.value = value.respond_to?(:call) ? value.call(key, locale, node) : value
          node.data[:path] = LocalePathname.replace_locale(node.data[:path], base, locale) if node.data.key?(:path)
        }
        data[locale] = data[locale].merge! m
      end
    end

    def fill_missing_google_translate(opts = {})
      from    = opts[:from] || base_locale
      locales = (Array(opts[:locales]).presence || self.locales) - [from]
      locales.each do |locale|
        keys   = missing_tree(locale, from).key_names.map(&:to_s)
        values = google_translate(keys.zip(keys.map(&t_proc(from))), to: locale, from: from).map(&:last)

        data[locale] = data[locale].merge! Data::Tree::Node.new(
            key: locale,
            children: Data::Tree::Siblings.from_flat_pairs(keys.zip(values))
        ).to_siblings
      end
    end

    def locales_for_update(opts)
      locales = (Array(opts[:locales] || opts[:locale]).presence || self.locales).map(&:to_s)
      # make sure base_locale always comes first if present
      locales = [base_locale] + (locales - [base_locale]) if locales.include?(base_locale)
      locales
    end
  end
end
