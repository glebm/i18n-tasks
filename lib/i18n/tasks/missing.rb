require 'i18n/tasks/task_helpers'
module I18n
  module Tasks
    module Missing
      include TaskHelpers
      extend self
      def perform
        (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
          trn = YAML.load_file(trn_path(locale))[locale]
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
