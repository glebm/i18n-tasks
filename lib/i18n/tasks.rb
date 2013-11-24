require 'i18n/tasks/version'
require 'i18n/tasks/railtie'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'term/ansicolor'

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

      def warn_deprecated(message)
        STDERR.puts Term::ANSIColor.yellow Term::ANSIColor.bold "i18n-tasks: [DEPRECATED] #{message}"
      end
    end
  end
end
