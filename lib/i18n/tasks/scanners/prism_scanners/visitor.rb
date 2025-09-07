# frozen_string_literal: true

require "prism/visitor"
require_relative "nodes"
require_relative "arguments_visitor"

# Implementation of Prism::Visitor (https://ruby.github.io/prism/rb/Prism/Visitor.html)
# It processes the parsed AST from Prism and creates a new AST with the nodes defined in prism_scanners/nodes.rb
# It defines processing of arguments in a way that is needed for the translation calls.
# The argument `rails` is used to determine if the scanner should handle Rails specific calls, such as
# `before_action`, `human_attribute_name`, and `model_name.human`.

module I18n::Tasks::Scanners::PrismScanners
  class Visitor < Prism::Visitor # rubocop:disable Metrics/ClassLength
    MAGIC_COMMENT_PREFIX = /\A.\s*i18n-tasks-use\s+/

    attr_reader(:calls, :current_module, :current_class, :current_method, :root)

    def initialize(rails: false, file_path: nil)
      @calls = []

      @current_module = nil
      @current_class = nil
      @current_method = nil
      @root = Root.new(file_path:, rails: rails)

      @rails = rails

      # Needs to have () because the Prism::Visitor has no arguments
      super()
    end

    def parent
      @current_before_action || @current_method || @current_class || @current_module || @root
    end

    def visit_module_node(node)
      previous_module = @current_module
      @current_module = parent.add_child(
        ParsedModule.new(node: node, parent: parent)
      )

      handle_comments(node)

      super
    ensure
      @current_module = previous_module
    end

    def visit_program_node(node)
      handle_comments(node)
      super
    end

    def visit_class_node(node)
      previous_class = @current_class

      @current_class = parent.add_child(
        ParsedClass.new(
          node: node,
          parent: parent,
          rails: @rails
        )
      )

      handle_comments(node)

      super
    ensure
      @current_class = previous_class
    end

    def visit_def_node(node)
      handle_comments(node)
      previous_method = @current_method
      parent = @current_class || @current_module || @root
      @current_method = parent.add_child(
        ParsedMethod.new(
          node: node,
          parent: parent,
          private_method: parent.private_method
        )
      )

      super
    ensure
      @current_method = previous_method
    end

    def visit_call_node(node)
      handle_comments(node)

      case node.name
      when :private
        @current_class&.private_methods!
      when :t, :t!, :translate, :translate!
        args, kwargs = process_arguments(node)
        parent.add_translation_call(
          TranslationCall.new(
            node: node,
            key: args[0],
            receiver: node.receiver,
            options: kwargs,
            parent: parent
          )
        )
      else
        handled_call = handle_rails_call_node(node) { super } if @rails

        return if handled_call

        parent.add_call(node)

      end

      super
    end

    def process
      @root.process
    end

    private

    def process_arguments(node)
      return [], {} if node.nil?
      return [], {} unless node.respond_to?(:arguments)
      return [], {} if node.arguments.nil?

      arguments_visitor = ArgumentsVisitor.new
      arguments = node.arguments.accept(arguments_visitor)
      keywords, args = arguments.partition { |arg| arg.is_a?(Hash) }

      [args.compact, keywords.first || {}]
    end

    def handle_comments(node)
      return if node.nil?
      return if node.comments.empty?

      node.comments.each do |comment|
        content =
          comment.respond_to?(:slice) ? comment.slice : comment.location.slice
        match = content.match(MAGIC_COMMENT_PREFIX)

        next if match.nil?

        string =
          content.gsub(MAGIC_COMMENT_PREFIX, "").delete("#").strip
        visitor = Visitor.new
        Prism
          .parse(string)
          .value
          .accept(visitor)

        # Process and remap the found translation calls to be for the found comment
        visitor.process.each do |comment_node|
          parent.add_translation_call(comment_node.with_node(node))
        end
      end
    end

    # ---- Rails specific methods ----
    # Returns true if the node was handled
    def handle_rails_call_node(node, &)
      case node.name
      when :before_action
        rails_handle_before_action(node, &)
      when :human_attribute_name
        rails_handle_human_attribute_name(node)
      when :human
        return if node.receiver.name != :model_name

        rails_handle_model_name(node)
      end
    end

    def rails_handle_before_action(node) # rubocop:disable Metrics/MethodLength
      before_action = ParsedBeforeAction.new(
        node: node,
        parent: @current_class
      )
      @current_class&.add_child(before_action)
      # Need to set current_before_action before processing arguments
      # since they can be lambdas that need to be processed in the context of the before_action
      @current_before_action = before_action
      array_arguments, keywords = process_arguments(node)
      first_argument = array_arguments.first

      if array_arguments.empty? && node.block.present?
        # No need to add data
      elsif first_argument.is_a?(String)
        before_action.name = first_argument
        before_action.only = keywords["only"]
        before_action.except = keywords["except"]
      elsif first_argument.try(:type) == :lambda_node
        before_action.only = keywords["only"]
        before_action.except = keywords["except"]
      else
        fail(
          ArgumentError,
          "Cannot handle before_action with this argument #{first_argument.class}"
        )
      end

      yield
    ensure
      @current_before_action = nil
    end

    def rails_handle_model_name(node)
      _args, kwargs = process_arguments(node)

      # We need to check for `node.receiver` since node is the `human` call
      model_name = if current_class.present? && rails_model_method_called_on_current_class?(node.receiver)
        current_class.path.flatten.map!(&:underscore).join(".")
      elsif node.receiver.present?
        node.receiver&.receiver&.name&.to_s&.underscore
      end

      return if model_name.nil?

      # Handle count being a symbol, e.g. count: :other
      count_key = case kwargs["count"]
      when Symbol, String
        kwargs["count"].to_s
      when Integer
        (kwargs["count"] > 1) ? "other" : "one"
      else
        "one"
      end

      parent.add_translation_call(
        TranslationCall.new(
          node: node,
          receiver: nil,
          key: [:activerecord, :models, model_name, count_key].join("."),
          parent: parent,
          options: kwargs
        )
      )
    end

    def rails_model_method_called_on_current_class?(node)
      node.receiver.nil? || (node.receiver&.name&.to_s == "class" && node.receiver.receiver&.is_a?(Prism::SelfNode))
    end

    def rails_handle_human_attribute_name(node)
      array_args, keywords = process_arguments(node)
      # Arguments empty or cannot be processed, e.g. if it is a call
      return unless array_args.size == 1 && keywords.empty?

      # Handle if called on `self.class` or if the current_class has `model_name.i18n_key`
      key = if current_class.present? && rails_model_method_called_on_current_class?(node)
        [
          :activerecord,
          :attributes,
          current_class.path.flatten.map!(&:underscore).join("."),
          array_args.first
        ].join(".")
      elsif node.receiver&.name.present?
        [
          :activerecord,
          :attributes,
          node.receiver.name.to_s.underscore,
          array_args.first
        ].join(".")
      else
        return
      end

      parent.add_translation_call(
        TranslationCall.new(
          node: node,
          key: key,
          receiver: nil,
          parent: parent,
          options: {}
        )
      )
    end
  end
end
