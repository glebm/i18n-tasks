require 'easy_translate'

module I18n::Tasks::Translation
  def translate(strings, opts)
    opts = opts.dup
    if (key = translation_config[:api_key]).present?
      opts[:key] = key
    end
    opts[:key] ||= ENV['GOOGLE_TRANSLATE_API_KEY']
    EasyTranslate.translate strings, opts
  end

  def translation_config
    @translation_config ||= begin
      (config[:translation] ||= {}).with_indifferent_access
    end
  end
end
