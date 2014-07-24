# coding: utf-8
require 'easy_translate'

module I18n::Tasks
  module GoogleTranslation
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
      list.each_with_index { |k_v, i| key_idx[k_v[0]] = i }
      list.group_by { |k_v|
        !!(k_v[0] =~ /[.\-_]html\z/.freeze)
      }.map do |html, slice|
        t_opts = opts.merge(html ? {html: true} : {format: 'text'})
        fetch_google_translations slice, t_opts
      end.reduce(:+).tap { |l|
        l.sort! { |a, b| key_idx[a[0]] <=> key_idx[b[0]] }
      }
    end

    def fetch_google_translations(list, opts)
      from_values(list, EasyTranslate.translate(to_values(list), opts)).tap do |result|
        if result.blank?
          raise CommandError.new('Google Translate returned no results. Make sure billing information is set at https://code.google.com/apis/console.')
        end
      end
    end

    private

    def to_values(list)
      list.map { |l| dump_value l[1] }.flatten(1)
    end

    def from_values(list, translated_values)
      keys                = list.map(&:first)
      untranslated_values = list.map(&:last)
      keys.zip parse_value(untranslated_values, translated_values.to_enum)
    end

    def dump_value(value)
      if value.is_a?(Array)
        # explode array
        value.map { |v| dump_value v }
      else
        replace_interpolations value
      end
    end

    def parse_value(untranslated, each_translated)
      if untranslated.is_a?(Array)
        # implode array
        untranslated.map { |from| parse_value(from, each_translated) }
      else
        value = each_translated.next
        restore_interpolations untranslated, value
      end
    end

    INTERPOLATION_KEY_RE  = /%\{[^}]+\}/.freeze
    UNTRANSLATABLE_STRING = 'zxzxzx'.freeze

    # 'hello, %{name}' => 'hello, <round-trippable string>'
    def replace_interpolations(value)
      value.gsub INTERPOLATION_KEY_RE, UNTRANSLATABLE_STRING
    end

    def restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE
      each_value = untranslated.scan(INTERPOLATION_KEY_RE).to_enum
      translated.gsub(Regexp.new(UNTRANSLATABLE_STRING, Regexp::IGNORECASE)) { each_value.next }
    end

    def warn_missing_api_key
      $stderr.puts Term::ANSIColor.red Term::ANSIColor.yellow 'Set Google API key via GOOGLE_TRANSLATE_API_KEY environmnet variable or translation.api_key in config/i18n-tasks.yml.
Get the key at https://code.google.com/apis/console.'
    end
  end
end
