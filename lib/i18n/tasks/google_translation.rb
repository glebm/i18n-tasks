require 'easy_translate'

module I18n::Tasks::GoogleTranslation
  # @param [Array] list of [key, value] pairs
  def google_translate(list, opts)
    return [] if list.empty?
    opts = opts.dup
    if !opts[:key] && (key = translation_config[:api_key]).present?
      opts[:key] = key
    end
    if opts[:key].blank?
      $stderr.puts(Term::ANSIColor.red Term::ANSIColor.yellow 'You may need to provide Google API key as GOOGLE_TRANSLATE_API_KEY env var or translation.api_key in config/i18n-tasks.yml.
You can obtain the key at https://code.google.com/apis/console.')
    end
    list.group_by { |k_v| k_v[0].end_with?('_html'.freeze) ? opts.merge(html: true) : opts.merge(format: 'text') }.map do |opts, strings|
      fetch_google_translations(strings, opts)
    end.reduce(:+)
  end

  INTERPOLATION_KEY_RE = /%\{[^}]+\}/
  UNTRANSLATABLE_STRING = 'zxzxzx'

  def fetch_google_translations(list, opts)
    translated = EasyTranslate.translate(list.map { |l| l[1].gsub(INTERPOLATION_KEY_RE, UNTRANSLATABLE_STRING) }, opts)
    translated.each_with_index { |translation, i|
      if (original = list[i][1]) =~ INTERPOLATION_KEY_RE
        interpolation_keys = original.scan(INTERPOLATION_KEY_RE)
        i = -1; translation.gsub!(Regexp.new(UNTRANSLATABLE_STRING, Regexp::IGNORECASE)) { interpolation_keys[i += 1] }
      end
    }
    list.map(&:first).zip(translated)
  end
end
