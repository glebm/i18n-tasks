require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Prefill < BaseTask
      # todo refactor to allow configuring output targets
      def perform
        # Will also rewrite en, good for ordering
        I18n.available_locales.map(&:to_s).each do |target_locale|
          data[target_locale] = data[base_locale].deep_merge(data[target_locale])
        end
      end
    end
  end
end
