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
      warn_missing_api_key
      return []
    end
    key_idx = {}
    list.each_with_index { |k_v, i| key_idx[k_v[0]] = i}
    list.group_by { |k_v|
      k_v[0].end_with?('_html'.freeze)
    }.map do |html, slice|
      t_opts = opts.merge(html ? {html: true} : {format: 'text'})
      fetch_google_translations slice, t_opts
    end.reduce(:+).tap { |l|
      l.sort! { |a, b| key_idx[a[0]] <=> key_idx[b[0]] }
    }
  end

  INTERPOLATION_KEY_RE = /%\{[^}]+\}/
  UNTRANSLATABLE_STRING = 'zxzxzx'

  def fetch_google_translations(list, opts)
    translated = EasyTranslate.translate(list.map { |l| l[1].gsub(INTERPOLATION_KEY_RE, UNTRANSLATABLE_STRING) }, opts)
    if translated.blank?
      raise CommandError.new('Google Translate returned no results. Make sure billing information is set at https://code.google.com/apis/console.')
    end
    translated.each_with_index { |translation, i|
      if (original = list[i][1]) =~ INTERPOLATION_KEY_RE
        interpolation_keys = original.scan(INTERPOLATION_KEY_RE)
        i = -1; translation.gsub!(Regexp.new(UNTRANSLATABLE_STRING, Regexp::IGNORECASE)) { interpolation_keys[i += 1] }
      end
    }
    list.map(&:first).zip(translated)
  end

  private

  def warn_missing_api_key
    $stderr.puts Term::ANSIColor.red Term::ANSIColor.yellow 'Set Google API key via GOOGLE_TRANSLATE_API_KEY environmnet variable or translation.api_key in config/i18n-tasks.yml.
Get the key at https://code.google.com/apis/console.'
  end
end
