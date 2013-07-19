require 'i18n/tasks/version'
require 'i18n/tasks/railtie'

module I18n
  module Tasks
    mattr_accessor :get_locale_data
    self.get_locale_data = lambda { |locale|
      YAML.load_file("config/locales/#{locale}.yml")
    }
  end
end
