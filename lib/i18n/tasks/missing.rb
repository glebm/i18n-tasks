require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask
      DESC = 'find all missing keys and missing translations'
      def perform
        $stderr.puts DESC
        # missing keys (in the code but not in base locale data)
        pattern_prefixes = find_source_pattern_prefixes
        find_source_keys.each do |key|
          if t(base[base_locale], key).blank? && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
            puts "#{red print_locale base_locale}  #{red "✗ #{bold 'none'}"}\t #{print_key key}"
          end
        end

        # missing translations (present in base locale, but untranslated in another locale )
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = get_locale_data(locale)[locale]
          traverse base[base_locale] do |key, base_value|
            translated = t(trn, key)
            data       = "\t #{print_key key} #{cyan base_value}"
            s = if translated.blank?
              "#{yellow bold '∅ blank'}#{data}"
            elsif translated == base_value
              "#{yellow bold "= #{base_locale}" }#{data}"
            end
            puts "#{print_locale locale}  #{s}" if s
          end
        end
      end

      private
      def print_locale(locale)
        ' ' + bold(locale.ljust(5))
      end

      def print_key(key)
        magenta(key).ljust(50)
      end

    end
  end
end
