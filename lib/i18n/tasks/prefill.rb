require 'i18n/tasks/task_helpers'
module I18n
  module Tasks
    module Prefill
      include TaskHelpers
      extend self
      def perform
        # Will also rewrite en, good for ordering
        I18n.available_locales.map(&:to_s).each do |target_locale|
          trn = YAML.load_file trn_path(target_locale)
          prefilled = { target_locale => base[base_locale] }.deep_merge(trn)
          File.open(trn_path(target_locale), 'w'){ |f| f.write prefilled.to_yaml }
        end
      end
    end
  end
end
