# frozen_string_literal: true

module I18n
  module Tasks
    module Plugins
      module Loader
        NAMESPACE = "I18n::Tasks::Plugins"

        # Load and register all plugins declared in +plugins_config+.
        #
        # Each key in +plugins_config+ is either a shorthand that maps to
        # +I18n::Tasks::Plugins::<CamelisedKey>+, or an arbitrary label when the
        # config entry carries an explicit +class:+ key.  An optional +require:+
        # key forces a specific require path; without it the path is derived from
        # the class name (Bundler-loaded gems need no explicit require).
        #
        # @param plugins_config [Hash, nil] the :plugins section from i18n-tasks.yml
        # @param registry [Registry]
        def self.load(plugins_config, registry)
          return unless plugins_config.present?

          plugins_config.each do |key, raw_config|
            config = (raw_config || {}).with_indifferent_access
            class_name = config.delete(:class).presence || key_to_class_name(key)
            req_path = config.delete(:require)

            ensure_loaded(class_name, req_path)
            ActiveSupport::Inflector.constantize(class_name).new(config).register(registry)
          end
        end

        def self.key_to_class_name(key)
          "#{NAMESPACE}::#{ActiveSupport::Inflector.camelize(key.to_s)}"
        end
        private_class_method :key_to_class_name

        def self.ensure_loaded(class_name, req_path)
          if req_path
            require req_path
          elsif !class_defined?(class_name)
            require class_name_to_path(class_name)
          end
        end
        private_class_method :ensure_loaded

        def self.class_defined?(class_name)
          ActiveSupport::Inflector.constantize(class_name)
          true
        rescue NameError
          false
        end
        private_class_method :class_defined?

        def self.class_name_to_path(class_name)
          ActiveSupport::Inflector.underscore(class_name)
        end
        private_class_method :class_name_to_path
      end
    end
  end
end
