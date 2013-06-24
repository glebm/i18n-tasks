require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask
      def perform
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = get_locale_data(locale)[locale]
          traverse base[base_locale] do |key, base_value|
            translated = t(trn, key)
            if translated.blank? || translated == base_value
              puts "#{locale}.#{key}: #{base_value}"
            end
          end
        end
      end
    end
  end
end
