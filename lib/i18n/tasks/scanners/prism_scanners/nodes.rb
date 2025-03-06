# frozen_string_literal: true

# These classes are used in the PrismScanners::Visitor class to store the translations found in the parsed code
# Used in the PrismScanners::Visitor class.
module I18n::Tasks::Scanners::PrismScanners
  class Root
    attr_reader(:calls, :translation_calls, :children, :node, :parent)

    def initialize(node: nil, parent: nil)
      @calls = []
      @translation_calls = []
      @children = []
      @node = node
      @parent = parent
    end

    def add_child(node)
      @children << node
      node
    end

    def add_call(node)
      @calls << node
    end

    def add_translation_call(translation_call)
      @translation_calls << translation_call
    end

    def support_relative_keys?
      false
    end

    def private_method
      false
    end

    def path
      []
    end

    def process
      (@translation_calls + @children.flat_map(&:process)).flatten
    end
  end

  class TranslationCall
    attr_reader(:node, :key, :receiver, :options, :parent)

    def initialize(node:, key:, receiver:, options:, parent:)
      @node = node
      @key = key
      @receiver = receiver
      @options = options
      @parent = parent
    end

    def relative_key?
      @key&.start_with?('.') && @receiver.nil?
    end

    def with_parent(parent)
      self.class.new(
        node: @node,
        key: @key,
        receiver: @receiver,
        options: @options,
        parent: parent
      )
    end

    def with_node(node)
      self.class.new(
        node: node,
        key: @key,
        receiver: @receiver,
        options: @options,
        parent: @parent
      )
    end

    def occurrences(file_path)
      occurrence(file_path)
    end

    def full_key
      return nil if key.nil?
      return nil unless key.is_a?(String)
      return nil if relative_key? && !support_relative_keys?

      parts = [scope]

      if relative_key?
        parts.concat(parent&.path || [])
        parts << key

        # TODO: Fallback to controller without action name
      elsif key.start_with?('.')
        parts << key[1..]
      else
        parts << key
      end

      parts.compact.join('.').gsub('..', '.')
    end

    private

    def scope
      return nil if @options.nil?
      return nil unless @options['scope']

      Array(@options['scope']).compact.map(&:to_s).join('.')
    end

    def occurrence(file_path)
      local_node = @node

      location = local_node.location

      final_key = full_key
      return nil if final_key.nil?

      [
        final_key,
        ::I18n::Tasks::Scanners::Results::Occurrence.new(
          path: file_path,
          line: local_node.respond_to?(:slice) ? local_node.slice : local_node.location.slice,
          pos: location.start_offset,
          line_pos: location.start_column,
          line_num: location.start_line,
          raw_key: key
        )
      ]
    end

    def occurrences_from_comments(file_path)
      Array(@comment_translations).flat_map do |child_node|
        child_node.with_context(
          path: @path,
          options: {
            **@context_options,
            comment_for_node: @node
          }
        ).occurrences(file_path)
      end
    end

    # Only public methods are added to the context path
    # Only some classes supports relative keys
    def support_relative_keys?
      parent.is_a?(ParsedMethod) && parent.support_relative_keys?
    end
  end

  class ParsedModule < Root
    def support_relative_keys?
      false
    end

    def private_method
      false
    end

    def path
      (@parent&.path || []) + [path_name]
    end

    def path_name
      @node.name.to_s.underscore
    end
  end

  class ParsedClass < Root
    attr_reader(:private_method)

    def initialize(node:, parent:, rails:)
      @private_method = false
      @methods = []
      @private_methods = []
      @before_actions = []
      @rails = rails

      super(node: node, parent: parent)
    end

    def add_child(node)
      case node
      when ParsedMethod
        if @private_method
          @private_methods << node
        else
          @methods << node
        end
      when ParsedBeforeAction
        @before_actions << node
      end

      super
    end

    def process # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return @children.flat_map(&:process) unless controller?

      methods_by_name = @methods.group_by(&:name)
      private_methods_by_name = @private_methods.group_by(&:name)

      # For each before_action we need to
      # - Find which method it calls
      # - Find out which methods it applies to
      # - Calculate translation calls (and see if they are relative)
      # - Add the translation calls to the methods it applies to

      @before_actions.each do |before_action|
        before_action_name = before_action.name&.to_sym
        method_call = methods_by_name[before_action_name]&.first || private_methods_by_name[before_action_name]&.first
        translation_calls = (method_call&.translation_calls || []) + before_action.translation_calls

        # We need to handle the parent here, should not be the before_action when it is called in the method.
        @methods.each do |method|
          next unless before_action.applies_to?(method.name)

          method.add_translation_call(
            translation_calls.map { |call| call.with_parent(method) }
          )
        end
      end

      nested_calls = {}
      new_translation_calls = []

      @methods.each do |method|
        method.calls.each do |call|
          next if call.receiver.present?

          other_method = methods_by_name[call.name]&.first || private_methods_by_name[call.name]&.first
          next unless other_method

          nested_calls[method.name] ||= []
          nested_calls[method.name] << other_method.name

          if nested_calls[call.name]&.include?(method.name)
            fail(ArgumentError, "Cyclic call detected: #{call.name} -> #{method.name}")
          end

          other_method.translation_calls.each do |translation_call|
            new_translation_calls.push(translation_call.with_parent(method))
          end
        end
      end

      @children.flat_map(&:process) + new_translation_calls
    end

    def private_methods!
      @private_method = true
    end

    def support_relative_keys?
      @rails && controller?
    end

    def path
      (@parent&.path || []) + [path_name]
    end

    def controller?
      @node.name.to_s.end_with?('Controller')
    end

    def path_name
      path = @node.constant_path.full_name_parts.map { |s| s.to_s.underscore }
      path.last.gsub!(/_controller\z/, '') if controller?

      path
    end
  end

  class ParsedMethod < Root
    def initialize(node:, parent:, private_method: false)
      @private_method = private_method

      super(node: node, parent: parent)
    end

    def support_relative_keys?
      !@private_method && @parent&.support_relative_keys?
    end

    def path
      (@parent&.path || []) + [@node.name]
    end

    def name
      @node.name
    end

    def process
      @translation_calls
    end
  end

  class ParsedBeforeAction < Root
    attr_reader(:name)

    def initialize(node:, parent:, name: nil, only: nil, except: nil)
      @name = name
      @only = only.present? ? Array(only).map(&:to_s) : nil
      @except = except.present? ? Array(except).map(&:to_s) : nil

      super(node: node, parent: parent)
    end

    def support_relative_keys?
      true
    end

    def applies_to?(method_name)
      if @only.nil? && @except.nil?
        true
      elsif @only.nil?
        !@except.include?(method_name.to_s)
      elsif @except.nil?
        @only.include?(method_name.to_s)
      else
        false
      end
    end

    def path
      @parent&.path || []
    end
  end
end
