require 'i18n/tasks/base_task'

module I18n
  module Tasks
    # Prefill values from base locale data
    class Prefill < BaseTask
      def perform
        I18n.available_locales.map(&:to_s).each do |target_locale|
          data[target_locale] = data[base_locale].deep_merge(data[target_locale])
        end
      end
    end
  end
end
