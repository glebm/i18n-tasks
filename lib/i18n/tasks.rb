# frozen_string_literal: true

# define all the modules to be able to use ::
module I18n
  module Tasks
    class << self
      def gem_path
        File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
      end

      def verbose?
        @verbose
      end

      attr_writer :verbose

      # Add a scanner to the default configuration.
      #
      # @param scanner_class_name [String]
      # @param scanner_opts [Hash]
      # @return self
      def add_scanner(scanner_class_name, scanner_opts = {})
        scanners = I18n::Tasks::Configuration::DEFAULTS[:search][:scanners]
        scanners << [scanner_class_name, scanner_opts]
        scanners.uniq!
        self
      end

      # Add commands to i18n-tasks
      #
      # @param commands_module [Module]
      # @return self
      def add_commands(commands_module)
        ::I18n::Tasks::Commands.send :include, commands_module
        self
      end
    end

    @verbose = !ENV['VERBOSE'].nil?

    module Data
    end
  end
end

require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
begin
  # activesupport >= 3
  require 'active_support/core_ext/object/try'
rescue LoadError => _e
  # activesupport ~> 2.3.2
  require 'active_support/core_ext/try'
end
require 'rainbow'
require 'erubi'

require 'i18n/tasks/version'
require 'i18n/tasks/base_task'

# Add internal locale data to i18n gem load path
require 'i18n'

Dir[File.join(I18n::Tasks.gem_path, 'config', 'locales', '*.yml')].each do |locale_file|
  I18n.config.load_path << locale_file
end

# Load pluralization data
require 'rails-i18n'
I18n.enforce_available_locales = false
RailsI18n::Railtie.add('rails/pluralization/*.rb')
