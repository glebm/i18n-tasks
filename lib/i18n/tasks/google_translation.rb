require 'easy_translate'

module I18n::Tasks::GoogleTranslation
  def google_translate(strings, opts)
    return [] if strings.empty?
    opts = opts.dup
    if (key = translation_config[:api_key]).present?
      opts[:key] ||= key
    end
    EasyTranslate.translate strings, opts
  end
end
