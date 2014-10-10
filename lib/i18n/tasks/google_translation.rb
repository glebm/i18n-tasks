# coding: utf-8
require 'easy_translate'
require 'i18n/tasks/html_keys'

module I18n::Tasks
  module GoogleTranslation

    def google_translate_forest(forest, from)
      forest.inject empty_forest do |result, root|
        translated = google_translate_list(root.key_values(root: true), to: root.key, from: from)
        result.merge! Data::Tree::Siblings.from_flat_pairs(translated)
      end
    end

    # @param [Array] list of [key, value] pairs
    def google_translate_list(list, opts)
      return [] if list.empty?
      opts       = opts.dup
      opts[:key] ||= translation_config[:api_key]
      validate_google_translate_api_key! opts[:key]
      key_pos = list.each_with_index.inject({}) { |idx, ((k, _v), i)| idx[k] = i; idx }
      result  = list.group_by { |k_v| HtmlKeys.html_key? k_v[0] }.map { |is_html, list_slice|
        fetch_google_translations list_slice, opts.merge(is_html ? {html: true} : {format: 'text'})
      }.reduce(:+) || []
      result.sort! { |a, b| key_pos[a[0]] <=> key_pos[b[0]] }
      result
    end

    def fetch_google_translations(list, opts)
      from_values(list, EasyTranslate.translate(to_values(list), opts)).tap do |result|
        if result.blank?
          raise CommandError.new(I18n.t('i18n_tasks.google_translate.errors.no_results'))
        end
      end
    end

    private

    def validate_google_translate_api_key!(key)
      if key.blank?
        raise CommandError.new('Set Google API key via GOOGLE_TRANSLATE_API_KEY environment variable or translation.api_key in config/i18n-tasks.yml.
Get the key at https://code.google.com/apis/console.')
      end
    end

    def to_values(list)
      list.map { |l| dump_value l[1] }.flatten.compact
    end

    def from_values(list, translated_values)
      keys                = list.map(&:first)
      untranslated_values = list.map(&:last)
      keys.zip parse_value(untranslated_values, translated_values.to_enum)
    end

    def dump_value(value)
      case value
        when Array
          # dump recursively
          value.map { |v| dump_value v }
        when String
          replace_interpolations value
        when Fixnum
          value.to_s
        else
          value
      end
    end

    def parse_value(untranslated, each_translated)
      case untranslated
        when Array
          # implode array
          untranslated.map { |from| parse_value(from, each_translated) }
        when String
          restore_interpolations untranslated, each_translated.next
        when NilClass
          nil
        when Fixnum
          untranslated
        else
          each_translated.next
      end
    end

    INTERPOLATION_KEY_RE  = /%\{[^}]+\}/.freeze
    UNTRANSLATABLE_STRING = 'zxzxzx'.freeze
    OBJECT_STRING = 'zyzyzy'.freeze
    OBJECT_STRING_REGEXP = /^zyzyzy/

    # 'hello, %{name}' => 'hello, <round-trippable string>'
    def replace_interpolations(value)
      value.gsub INTERPOLATION_KEY_RE, UNTRANSLATABLE_STRING
    end

    def restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE
      each_value = untranslated.scan(INTERPOLATION_KEY_RE).to_enum
      translated.gsub(Regexp.new(UNTRANSLATABLE_STRING, Regexp::IGNORECASE)) { each_value.next }
    end
  end
end
