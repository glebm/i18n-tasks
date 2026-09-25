# frozen_string_literal: true

module I18n
  module Tasks
    module Plugins
      class Registry
        attr_reader :scanners_to_add, :scanner_excludes

        def initialize
          @hooks = Hash.new { |h, k| h[k] = [] }
          @scanners_to_add = []
          @scanner_excludes = Hash.new { |h, k| h[k] = [] }
        end

        # @param hook_name [Symbol]
        # @return [self]
        def on(hook_name, &block)
          @hooks[hook_name] << block
          self
        end

        # Declare an additional scanner.
        # @param class_name [String] fully qualified scanner class name
        # @param options [Hash] scanner options (only:, exclude:, etc.)
        # @return [self]
        def add_scanner(class_name, **options)
          @scanners_to_add << [class_name, options]
          self
        end

        # Declare a glob pattern to exclude from an existing scanner.
        # @param scanner_class [String] fully qualified scanner class name
        # @param pattern [String]
        # @return [self]
        def exclude_from_scanner(scanner_class, pattern)
          @scanner_excludes[scanner_class] << pattern
          self
        end

        # Reduce-chain hook: each registered block transforms the primary value.
        # The block receives +value+ as first positional arg plus +context+ as keyword args,
        # and should return the transformed value (returning nil keeps the previous value).
        # @param hook_name [Symbol]
        # @param value the primary value to transform
        # @param context [Hash] additional read-only context
        # @return the final transformed value, or +value+ if no hooks are registered
        def reduce(hook_name, value, **context)
          @hooks[hook_name].reduce(value) { |v, hook| hook.call(v, **context) || v }
        end

        # Collect-chain hook: each block contributes additional items.
        # @param hook_name [Symbol]
        # @param context [Hash] keyword args passed to each block
        # @return [Array] flat array of all collected items
        def collect(hook_name, **context)
          @hooks[hook_name].flat_map { |hook| hook.call(**context) }
        end
      end
    end
  end
end
