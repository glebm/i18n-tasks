require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Prefill < BaseTask
      def perform
        # Will also rewrite en, good for ordering
        I18n.available_locales.map(&:to_s).each do |target_locale|
          trn = get_locale_data(target_locale)
          prefilled = { target_locale => base_locale_data }.deep_merge(trn)
          File.open(locale_file_path(target_locale), 'w'){ |f| f.write prefilled.to_yaml }
        end
      end
    end
  end
end
