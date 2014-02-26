task :environment do
  Thread.exclusive do
    I18n.default_locale    = 'en'
    I18n.available_locales = %w(en es)
  end
end

namespace :i18n do
  task :setup => 'environment'
end
