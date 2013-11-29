require 'i18n/tasks/version'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'term/ansicolor'
require 'erubis'
require 'i18n/tasks/railtie' if defined?(Rails)

module I18n
  module Tasks
    CONFIG_FILES = %w(
      config/i18n-tasks.yml config/i18n-tasks.yml.erb
      i18n-tasks.yml i18n-tasks.yml.erb
    )
    class << self
      def config
        @config ||= begin
          file = File.read(CONFIG_FILES.detect { |f| File.exists?(f) })
          file = YAML.load(Erubis::Eruby.new(file).result) if file.present?
          HashWithIndifferentAccess.new.merge(file.presence || {})
        end
      end

      def warn_deprecated(message)
        STDERR.puts Term::ANSIColor.yellow Term::ANSIColor.bold "i18n-tasks: [DEPRECATED] #{message}"
      end
    end
  end
end
