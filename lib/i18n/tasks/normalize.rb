require 'i18n/tasks/base_task'

module I18n
  module Tasks
    # Normalize keys (sort and put into the right files)
    class Normalize < BaseTask
      def perform
        locales.each do |target_locale|
          data[target_locale] = data[target_locale]
        end
      end
    end
  end
end
