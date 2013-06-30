# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask
      DESC = 'find all missing keys and missing translations'

      def perform
        $stderr.puts DESC
        missing = find_missing
        missing.sort_by { |m| m[:type] }.each do |m|
          locale, key, base_value = m[:locale], m[:key], m[:base_value]
          case m[:type]
            when :none
              puts "#{red p_locale base_locale}  #{red "✗ #{bold 'none'}"} #{p_key key}"
            when :blank
              puts "#{p_locale locale}  #{yellow bold '∅ blank'} #{p_key key} #{cyan base_value}"
            when :eq_base
              puts "#{p_locale locale}  #{yellow bold "= #{base_locale}"} #{p_key key} #{cyan base_value}"
          end
        end
      end

      private

      def find_missing
        missing = []

        # missing keys (in the code but not in base locale data)
        pattern_prefixes = find_source_pattern_prefixes
        find_source_keys.each do |key|
          if t(base[base_locale], key).blank? && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
            missing << {locale: :en, type: :none, key: key}
          end
        end

        # missing translations (present in base locale, but untranslated in another locale )
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = get_locale_data(locale)[locale]
          traverse base[base_locale] do |key, base_value|
            translated = t(trn, key)
            if translated.blank?
              missing << {locale: locale, key: key, type: :blank, base_value: base_value}
            elsif translated == base_value
              missing << {locale: locale, key: key, type: :eq_base, base_value: base_value}
            end
          end
        end

        missing
      end

      def p_locale(locale)
        ' ' + bold(locale.ljust(5))
      end

      def p_key(key)
        magenta(key).ljust(50)
      end

    end
  end
end
