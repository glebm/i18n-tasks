task :environment do
  I18n.default_locale = 'en'
  I18n.available_locales = %w(en es)
end

namespace :i18n do
  task :setup => 'environment'
end
