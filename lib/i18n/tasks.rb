require 'i18n/tasks/version'
require 'i18n/tasks/railtie'
require 'i18n/tasks/key_pattern_matching'

require 'i18n/tasks/data/yaml'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/string/access'

module I18n
  module Tasks
    CONFIG_FILE = 'config/i18n-tasks.yml'
    class << self
      def config
        @config ||= begin
          file = File.read(CONFIG_FILE) if File.exists?(CONFIG_FILE)
          file = YAML.load(file) if file.present?
          HashWithIndifferentAccess.new.merge(file.presence || {})
        end
      end
    end
  end
end
