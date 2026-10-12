# frozen_string_literal: true

module I18n
  module Tasks
    module Plugins
      # Base class for i18n-tasks plugins.  Subclasses get a class-level DSL for
      # declaring hooks and scanner configuration; the +register+ instance method
      # is provided and does not need to be overridden.
      #
      # Usage:
      #
      #   class MyPlugin < I18n::Tasks::Plugins::BasePlugin
      #     def initialize(config = {})
      #       @root = config[:root]
      #     end
      #
      #     register_hook :load_locale do |data, path:|
      #       # `self` is the plugin instance — @root and private methods are accessible
      #       next data unless path.start_with?(@root)
      #       transform(data)
      #     end
      #   end
      #
      class BasePlugin
        # Declare a hook callback executed in the context of the plugin instance.
        # Multiple calls stack; hooks run in declaration order.
        #
        # @param name [Symbol] hook name (e.g. :load_locale)
        def self.register_hook(name, &block)
          _plugin_hooks << [name, block]
        end

        # Declare an additional scanner to add to the search config.
        # @param class_name [String]
        # @param options [Hash]
        def self.add_scanner(class_name, **options)
          _plugin_scanners_to_add << [class_name, options]
        end

        # Declare a glob pattern to exclude from an existing scanner.
        # @param scanner_class [String]
        # @param pattern [String]
        def self.exclude_from_scanner(scanner_class, pattern)
          _plugin_scanner_excludes[scanner_class] << pattern
        end

        def self._plugin_hooks
          @_plugin_hooks ||= []
        end

        def self._plugin_scanners_to_add
          @_plugin_scanners_to_add ||= []
        end

        def self._plugin_scanner_excludes
          @_plugin_scanner_excludes ||= Hash.new { |h, k| h[k] = [] }
        end

        # Wires all declared hooks and scanner config into +registry+.
        # Called by the plugin loader — subclasses do not need to override this.
        def register(hooks)
          self.class._plugin_hooks.each do |(name, block)|
            hooks.on(name) { |*args, **kwargs| instance_exec(*args, **kwargs, &block) }
          end

          self.class._plugin_scanners_to_add.each do |(class_name, options)|
            hooks.add_scanner(class_name, **options)
          end

          self.class._plugin_scanner_excludes.each do |scanner_class, patterns|
            patterns.each { |pattern| hooks.exclude_from_scanner(scanner_class, pattern) }
          end
        end
      end
    end
  end
end
