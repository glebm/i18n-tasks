module I18n
  module Tasks
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load 'tasks/i18n-tasks.rake'
        namespace :i18n do
          task :setup => 'environment'
        end
      end
    end
  end
end
