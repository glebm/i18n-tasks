# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask
      extend Term::ANSIColor
      DESC = 'Missing keys and translations'
      LEGEND = <<-TEXT
        Legend: #{red '✗'} key missing, #{yellow bold '∅'} translation blank, #{yellow bold '='} value equal to base locale.
      TEXT
      STATUS_TEXTS = {
          none:     red("✗".ljust(6)),
          blank:    yellow(bold '∅'.ljust(6)),
          eq_base:  yellow(bold "=".ljust(6))
      }

      def perform
        missing = find_missing
        $stderr.puts bold cyan "#{DESC} (#{missing.length})"
        $stderr.puts cyan LEGEND
        missing.each { |m| print_missing_translation m }
      end

      # get all the missing translations as list of missing keys as hashes with:
      #  {:locale, :key, :type, and optionally :base_value}
      #  :type — :blank, :missing, or :eq_base
      #  :base_value — translation value in base locale if one is present
      def find_missing
        # missing keys, i.e. key that are in the code but are not in the base locale data
        missing = find_source_keys.reject { |key|
          key_has_value?(key, base_locale) || pattern_key?(key) || ignore_key?(key, :missing)
        }.map do |key|
          {locale: base_locale, type: :none, key: key}
        end

        # missing translations (present in base locale, but untranslated in another locale )
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = get_locale_data(locale)[locale]
          traverse base_locale_data do |key, base_value|
            value_in_locale = t(trn, key)
            if value_in_locale.blank? && !ignore_key?(key, :missing)
              missing << {locale: locale, key: key, type: :blank, base_value: base_value}
            elsif value_in_locale == base_value && !ignore_key?(key, :eq_base, locale)
              missing << {locale: locale, key: key, type: :eq_base, base_value: base_value}
            end
          end
        end

        # sort first by locale, then by type
        missing.sort { |a,b| (l = a[:locale] <=> b[:locale]).zero? ? a[:type] <=> b[:type] : l }
      end

      private

      def print_missing_translation(m)
        locale, key, base_value, status_text = m[:locale], m[:key], m[:base_value], " #{STATUS_TEXTS[m[:type]]}"

        s = if m[:type] == :none
              "#{red p_locale base_locale} #{status_text} #{p_key key}"
            else
              "#{p_locale locale} #{status_text} #{p_key key} #{cyan base_value}"
            end
        puts s
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
