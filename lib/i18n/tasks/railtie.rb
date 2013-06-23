require 'rails'
module I18n
  module Tasks
    class Railtie < ::Rails::Railtie
      rake_tasks {
        load "tasks/i18n-tasks.rake"
      }
    end
  end
end
