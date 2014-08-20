module I18n::Tasks
  module LocalePathname
    extend self

    def replace_locale(path, from, to)
      path && path.sub(path_locale_re(from), to)
    end

    private

    def path_locale_re(locale)
      (@path_locale_res ||= {})[locale] ||= /(?<=^|[\/.])#{locale}(?=\.)/.freeze
    end
  end
end
