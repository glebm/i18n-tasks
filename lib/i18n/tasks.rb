require 'i18n/tasks/version'
require 'i18n/tasks/railtie'
require 'active_support/hash_with_indifferent_access'

module I18n
  module Tasks
    mattr_accessor :get_locale_data
    self.get_locale_data = lambda { |locale|
      YAML.load_file("config/locales/#{locale}.yml")
    }

    CONFIG_FILE = 'config/i18n-tasks.yml'
    class << self
      def config
        @config ||= HashWithIndifferentAccess.new.merge(File.exists?(CONFIG_FILE) ? YAML.load_file(CONFIG_FILE) : {})
      end
    end
  end
end
