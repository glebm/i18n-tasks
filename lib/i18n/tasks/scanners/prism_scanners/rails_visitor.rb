# frozen_string_literal: true

require_relative 'visitor'
require_relative 'nodes'

# Extends the PrismScanners::Visitor class to add Rails-specific processing.
# Supports:
# - ControllerNodes
# - BeforeActionNodes
# - TranslationNodes
# - ModelNameNodes
# - HumanAttributeNameNodes

module I18n::Tasks::Scanners::PrismScanners
  class RailsVisitor < Visitor
    def visit_class_node(node)
      class_name = node.name.to_s
      class_object =
        if class_name.end_with?('Controller')
          ControllerNode.new(node: node)
        else
          ClassNode.new(node: node)
        end

      node
        .body
        .body
        .map { |n| visit(n) }
        .each { |child_node| class_object.add_child_node(child_node) }

      class_object
    end

    def visit_call_node(node)
      # TODO: How to handle multiple comments for same row?
      comment_translations =
        @comment_translations_by_row[node.location.start_line - 1]
      case node.name
      when :private
        @private_methods = true
        node
      when :before_action
        handle_before_action(node)
      when :t, :'I18n.t', :t!, :'I18n.t!', :translate, :translate!
        handle_translation_call(node, comment_translations)
      when :human_attribute_name
        handle_human_attribute_name(node)
      when :model_name
        ModelNameNode.new(node: node, model: visit(node.receiver))
      when :human
        handle_human_call(node, comment_translations)
      else
        CallNode.new(node: node, comment_translations: comment_translations)
      end
    end

    def handle_translation_call(node, comment_translations)
      array_args, keywords = process_arguments(node)
      key = array_args.first

      receiver = visit(node.receiver) if node.receiver

      TranslationNode.new(
        node: node,
        key: key,
        receiver: receiver,
        options: keywords,
        comment_translations: comment_translations
      )
    end

    def handle_before_action(node) # rubocop:disable Metrics/MethodLength
      array_arguments, keywords = process_arguments(node)
      if array_arguments.empty? || array_arguments.size > 2
        fail(
          ArgumentError,
          "Cannot handle before_action with these arguments #{node.slice}"
        )
      end
      first_argument = array_arguments.first

      if first_argument.is_a?(String)
        BeforeActionNode.new(
          node: node,
          name: first_argument,
          only: keywords['only'],
          except: keywords['except']
        )
      elsif first_argument.is_a?(Prism::StatementsNode)
        BeforeActionNode.new(
          node: node,
          translation_nodes: visit(first_argument),
          only: keywords['only'],
          except: keywords['except']
        )
      else
        fail(
          ArgumentError,
          "Cannot handle before_action with this argument #{first_argument.type}"
        )
      end
    end

    def handle_human_call(node, comment_translations)
      _array_args, keywords = process_arguments(node)
      receiver = visit(node.receiver)
      if receiver.type == :model_name_node
        ModelNameNode.new(
          node: node,
          model: receiver.model,
          count: keywords['count']
        )
      else
        CallNode.new(node: node, comment_translations: comment_translations)
      end
    end

    def handle_human_attribute_name(node)
      array_args, keywords = process_arguments(node)
      unless array_args.size == 1 && keywords.empty?
        fail(
          ArgumentError,
          'human_attribute_name should have only one argument'
        )
      end

      HumanAttributeNameNode.new(
        node: node,
        model: visit(node.receiver),
        argument: array_args.first
      )
    end
  end
end
