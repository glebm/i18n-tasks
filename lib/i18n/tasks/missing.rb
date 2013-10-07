# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask
      DESC = 'Missing keys and translations'

      def initialize
        @legend = <<-TEXT
        Legend: #{red '✗'} key missing, #{yellow bold '∅'} translation blank, #{yellow bold '='} value equal to base locale.
        TEXT
        @status_texts = {
            none:     red("✗".ljust(6)),
            blank:    yellow(bold '∅'.ljust(6)),
            eq_base:  yellow(bold "=".ljust(6))
        }
      end

      def perform
        missing = find_missing
        $stderr.puts bold cyan "#{DESC} (#{missing.length})"
        $stderr.puts cyan @legend
        missing.each do |m|
          print_missing_translation m
        end
      end

      # get all the missing translations as list of missing keys as hashes with:
      #  {:locale, :key, :type, and optionally :base_value}
      #  :type — :blank, :missing, or :eq_base
      #  :base_value — translation value in base locale if one is present
      def find_missing
        # dynamically generated keys in the source, e.g t("category.#{category_key}")
        pattern_re = compile_start_with_re find_source_pattern_prefixes

        # missing keys (in the code but not in base locale data)
        keys = find_source_keys
        missing = keys.select { |key| t(base[base_locale], key).blank? && key !~ pattern_re && key !~ ignore_pattern(:missing) }.map do |key|
          {locale: base_locale, type: :none, key: key}
        end

        # missing translations (present in base locale, but untranslated in another locale )
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = get_locale_data(locale)[locale]
          traverse base[base_locale] do |key, base_value|
            translated = t(trn, key)
            if translated.blank? && key !~ ignore_pattern(:missing)
              missing << {locale: locale, key: key, type: :blank, base_value: base_value}
            elsif translated == base_value && key !~ ignore_pattern(:eq_base, locale)
              missing << {locale: locale, key: key, type: :eq_base, base_value: base_value}
            end
          end
        end

        missing.sort { |a,b| (l = a[:locale] <=> b[:locale]).zero? ? a[:type] <=> b[:type] : l }
      end

      private

      def print_missing_translation(m)
        locale, key, base_value, status_text = m[:locale], m[:key], m[:base_value], " #{@status_texts[m[:type]]}"

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
