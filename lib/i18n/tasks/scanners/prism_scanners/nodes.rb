# frozen_string_literal: true

# This file defines the nodes that will be returned by the PrismScanners Visitor-class.
# All nodes inherit from BaseNode and all implement `translation_nodes` which returns the final nodes
# which can be used to extract all occurrences.

# Ruby:
# - ModuleNode: Represents a Ruby module
# - ClassNode: Represents a Ruby class
# - DefNode: Represents a Ruby method
# - CallNode: Represents a Ruby method call

# Rails:
# - ControllerNode: Represents a controller
# - BeforeActionNode: Represents a before_action in a controller
# - HumanAttributeNameNode: Represents a human_attribute_name call
# - ModelNameNode: Represents a model_name call

module I18n::Tasks::Scanners::PrismScanners
  class BaseNode
    MAGIC_COMMENT_PREFIX = /\A.\s*i18n-tasks-use\s+/.freeze
    MAGIC_COMMENT_SKIP_PRISM = 'i18n-tasks-skip-prism'

    attr_reader(:node)

    def initialize(node:)
      @node = node
      @prepared = false
    end

    def support_relative_keys?
      false
    end

    def prepare
      @prepared = true
    end
  end

  class ModuleNode < BaseNode
    def initialize(node:, child_nodes:)
      @node = node
      @child_nodes = child_nodes
      super(node: node)
    end

    def inspect
      "<ModuleNode: ##{name}>"
    end

    def type
      :module_node
    end

    def name
      @node.name.to_s
    end

    def path_name
      name.to_s.underscore
    end

    def translation_nodes(path: nil, options: nil)
      @child_nodes.flat_map do |child_node|
        next unless child_node.respond_to?(:translation_nodes)

        child_node.translation_nodes(path: [*path, self], options: options)
      end
    end
  end

  class ClassNode < BaseNode
    attr_reader(:methods, :calls)

    def initialize(node:)
      @def_nodes = []
      @calls = []

      super
    end

    def inspect
      "<ClassNode: ##{@node.name}>"
    end

    def add_child_node(child_node)
      if child_node.instance_of?(DefNode)
        @def_nodes << child_node
      else
        @calls << child_node
      end
    end

    def path_name
      path = @node.constant_path.full_name_parts.map { |s| s.to_s.underscore }

      path.last.gsub!(/_controller\z/, '') if class_type == :controller

      path
    end

    def translation_nodes(path: nil, options: nil)
      prepare unless @prepared
      options ||= {}
      local_path = [*path, self]
      @def_nodes
        .filter_map do |method|
          next unless method.respond_to?(:translation_nodes)

          method.translation_nodes(
            path: local_path,
            options: {
              **options,
              before_actions: @before_actions,
              def_nodes: @def_nodes
            }
          )
        end
        .flatten
    end

    def type
      :class_node
    end

    def class_type
      class_name = @node.name.to_s
      if class_name.end_with?('Controller')
        :controller
      elsif class_name.end_with?('Helper')
        :helper
      elsif class_name.end_with?('Mailer')
        :mailer
      elsif class_name.end_with?('Job')
        :job
      elsif class_name.end_with?('Component')
        :component
      else
        :ruby_class
      end
    end
  end

  class ControllerNode < ClassNode
    def initialize(node:)
      @before_actions = []
      super
    end

    def add_child_node(child_node)
      if child_node.instance_of?(BeforeActionNode)
        @before_actions << child_node
      else
        super
      end
    end

    def prepare
      @before_actions.each do |before_action|
        next if before_action.name.nil?

        before_action.add_method(
          @def_nodes.find do |method|
            method.name.to_s == before_action.name.to_s
          end
        )
      end

      super
    end

    def class_type
      :controller
    end

    def support_relative_keys?
      true
    end
  end

  class DefNode < BaseNode
    attr_reader(:private_method)

    def initialize(node:, calls:, private_method:)
      @node = node
      @calls = calls
      @private_method = private_method
      @called_from = []
      super(node: node)
    end

    def inspect
      "<DefNode: ##{name}, #{private_method ? 'private' : 'public'}>"
    end

    def add_call_from(method_name)
      fail(ArgumentError, "Cyclic call detected: #{method_name} -> #{name}") if @called_from.include?(method_name)

      @called_from << method_name
    end

    def path_name
      name unless private_method
    end

    def name
      @node.name.to_s
    end

    def type
      :def_node
    end

    def translation_nodes(path: nil, options: nil)
      local_path = [*path]

      local_path << self if !local_path.last.instance_of?(DefNode) && !private_method

      before_action_translation_nodes(path: local_path, options: options) +
        translation_nodes_from_calls(path: local_path, options: options)
    end

    def translation_nodes_from_calls(path: nil, options: nil)
      other_def_nodes = options[:def_nodes] || []
      @calls
        .filter_map do |call|
          case call.type
          when :translation_node
            call.with_context(path: path, options: options)
          else
            other_method =
              other_def_nodes&.find { |m| m.name.to_s == call.name.to_s }
            next if other_method.nil?

            other_method.add_call_from(@node.name.to_s)
            other_method.translation_nodes(path: path, options: options)
          end
        end
        .flatten(1)
    end

    def before_action_translation_nodes(path: nil, options: nil)
      before_actions = options[:before_actions]
      return [] if private_method || before_actions.nil?

      before_actions
        .select { |action| action.applies_to?(name) }
        .flat_map do |action|
          action.translation_nodes(path: path, options: options)
        end
    end
  end

  class TranslationNode < BaseNode
    attr_reader(:key, :node, :options)

    def initialize( # rubocop:disable Metrics/ParameterLists
      node:,
      key:,
      receiver:,
      options: nil,
      comment_translations: nil,
      path: nil,
      context_options: nil
    )
      @node = node
      @key = key
      @receiver = receiver
      @options = options
      @comment_translations = comment_translations
      @path = path
      @context_options = context_options || {}

      super(node: node)
    end

    def inspect
      "<TranslationNode: #{key}, #{@path}>"
    end

    def with_context(path: nil, options: nil)
      TranslationNode.new(
        node: @node,
        key: @key,
        receiver: @receiver,
        options: @options,
        path: path,
        context_options: options,
        comment_translations: @comment_translations
      )
    end

    def type
      :translation_node
    end

    def relative_key?
      @key&.start_with?('.') && @receiver.nil?
    end

    def occurrences(file_path)
      occurrences = occurrences_from_comments(file_path)

      main_occurrence = occurrence(file_path)
      return occurrences if main_occurrence.nil?

      occurrences << main_occurrence

      occurrences.concat(
        options
          &.values
          &.filter { |n| n.is_a?(TranslationNode) }
          &.flat_map do |n|
            n.with_context(path: @path, options: @context_options).occurrences(
              file_path
            )
          end || []
      ).compact
    end

    def full_key(context_path:)
      return nil if key.nil?
      return nil unless key.is_a?(String)
      return nil if relative_key? && !support_relative_keys?(context_path)

      parts = [scope]

      if relative_key?
        path = Array(context_path).map(&:path_name)
        parts.concat(path)
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
      local_node = @context_options[:comment_for_node] || @node

      location = local_node.location

      final_key = full_key(context_path: @path || [])
      return nil if final_key.nil?

      [
        final_key,
        ::I18n::Tasks::Scanners::Results::Occurrence.new(
          path: file_path,
          line: local_node.slice,
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
    def support_relative_keys?(context_path)
      context_path.any? { |node| node.instance_of?(DefNode) } &&
        context_path.any?(&:support_relative_keys?)
    end
  end

  class BeforeActionNode < BaseNode
    attr_reader(:name)

    def initialize(node:, only:, except:, name: nil, translation_nodes: nil)
      @node = node
      @name = name
      @only = only.present? ? Array(only).map(&:to_s) : nil
      @except = except.present? ? Array(except).map(&:to_s) : nil
      @translation_nodes = translation_nodes
      @method = nil

      super(node: node)
    end

    def inspect
      "<BeforeActionNode: #{@name}>"
    end

    def type
      :before_action_node
    end

    def calls
      @method&.calls || []
    end

    def add_method(method)
      fail(ArgumentError, 'BeforeAction already has a method') if @method.present?
      fail(ArgumentError, 'BeforeAction already has translations') if @translation_nodes

      @method = method
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

    def translation_nodes(path: nil, options: nil)
      if @translation_nodes.present?
        @translation_nodes.flat_map do |child_node|
          child_node.with_context(path: path, options: options)
        end
      elsif @method.present?
        @method.translation_nodes(path: path, options: options)
      else
        []
      end
    end
  end

  class HumanAttributeNameNode < BaseNode
    def initialize(node:, model:, argument:)
      @node = node
      @model = model
      @argument = argument
      super(node: node)
    end

    def type
      :human_attribute_name_node
    end

    def translation_nodes(path: nil, options: nil)
      [
        TranslationNode.new(
          node: @node,
          receiver: nil,
          key: key,
          path: path,
          options: options
        )
      ]
    end

    def key
      ['activerecord.attributes', @model.to_s.underscore, @argument.to_s].join(
        '.'
      )
    end
  end

  class ModelNameNode < BaseNode
    attr_reader(:model)

    def initialize(node:, model:, count: nil)
      @node = node
      @model = model
      @count = count
      super(node: node)
    end

    def type
      :model_name_node
    end

    def translation_nodes(path: nil, options: nil)
      [
        TranslationNode.new(
          node: @node,
          receiver: nil,
          key: key,
          path: path,
          options: options
        )
      ]
    end

    def count_key
      if @count.nil? || @count <= 1
        'one'
      else
        'other'
      end
    end

    def key
      ['activerecord.models', @model.to_s.underscore, count_key].join('.')
    end
  end

  class CallNode < BaseNode
    def initialize(node:, comment_translations:)
      @comment_translations = comment_translations || []
      @node = node
      super(node: node)
    end

    def type
      :call_node
    end

    def name
      @node.name
    end

    def translation_nodes(path: nil, options: nil)
      options ||= {}
      @comment_translations.map do |child_node|
        child_node.with_context(
          path: path,
          options: {
            **options,
            comment_for_node: @node
          }
        )
      end
    end
  end
end
