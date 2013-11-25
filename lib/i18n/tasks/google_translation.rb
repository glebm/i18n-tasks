require 'easy_translate'

module I18n::Tasks::GoogleTranslation
  def google_translate(strings, opts)
    return [] if strings.empty?
    opts = opts.dup
    if (key = translation_config[:api_key]).present?
      opts[:key] ||= key
    end
    if opts[:key].blank?
      $stderr.puts(Term::ANSIColor.red Term::ANSIColor.yellow 'You may need to provide Google API key as GOOGLE_TRANSLATE_API_KEY or in config/i18n-tasks.yml.
You can obtain the key at https://code.google.com/apis/console.')
    end
    EasyTranslate.translate strings, opts
  end
end
