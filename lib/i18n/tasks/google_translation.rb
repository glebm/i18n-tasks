require 'easy_translate'

module I18n::Tasks::GoogleTranslation
  # @param [Array] list of [key, value] pairs
  def google_translate(list, opts)
    return [] if list.empty?
    opts = opts.dup
    if (key = translation_config[:api_key]).present?
      opts[:key] ||= key
    end
    if opts[:key].blank?
      $stderr.puts(Term::ANSIColor.red Term::ANSIColor.yellow 'You may need to provide Google API key as GOOGLE_TRANSLATE_API_KEY or in config/i18n-tasks.yml.
You can obtain the key at https://code.google.com/apis/console.')
    end
    list.group_by { |k_v| k_v[0].end_with?('_html'.freeze) ? opts.merge(html: true) : opts }.map do |opts, strings|
      strings.map(&:first).zip EasyTranslate.translate(strings.map(&:second), opts)
    end.reduce(:+)
  end
end
