class I18n::Tasks::Translate < I18n::Tasks::BaseTask
  def perform(to_locales = locales)
    from_locale = base_locale
    (Array(to_locales) - [from_locale]).each do |locale|
      to_translate = []
      traverse data[from_locale] do |key, value|
        to_translate << [key, value] unless key_has_value?(locale)
      end

      translated = to_translate.map(&:first).zip(
          translate(to_translate.map(&:last), to: locale, from: from_locale)
      )

      data[locale] = data[locale].merge(list_to_tree(translated))
    end
  end
end