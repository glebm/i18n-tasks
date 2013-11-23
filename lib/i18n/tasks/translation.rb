require 'easy_translate'

module I18n::Tasks::Translation
  def google_translate(strings, opts)
    return [] if strings.empty?
    opts = opts.dup
    if (key = translation_config[:api_key]).present?
      opts[:key] ||= key
    end
    EasyTranslate.translate strings, opts
  end

  def translation_config
    @translation_config ||= begin
      conf           = (config[:translation] ||= {}).with_indifferent_access
      conf[:api_key] ||= ENV['GOOGLE_TRANSLATE_API_KEY']
      conf
    end
  end
end
