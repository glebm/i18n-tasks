module I18n::Tasks
  module LocalePathname
    extend self

    def replace_locale(path, from, to)
      path.try :sub, /(^|[\/.])#{from}(?=\.)/, "\\1#{to}"
    end
  end
end
