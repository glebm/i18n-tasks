# frozen_string_literal: true

require 'prism'
require 'i18n/tasks/scanners/results/key_occurrences'

module I18n::Tasks::Scanners
  class PrismRailsControllerParser
    DOT = '.'

    def process_path(path)
      parse_results = Prism.parse_file(path)

      visitor = PrismControllerVisitor.new

      parse_results.value.accept(visitor)

      visitor.translation_calls(path)
    end

    class TranslationNode
      attr_reader(:key, :node)

      def initialize(node:, key:, options: nil)
        @node = node
        @key = key
        @options = options
      end

      def type
        :translation_node
      end

      def location
        @node.location
      end

      def relative_key?
        @key.start_with?(DOT)
      end

      def to_occurrence(path, controller_key, method, node)
        location = node.location

        final_key = full_key(controller_key, method)
        return nil if final_key.nil?

        [
          final_key,
          ::I18n::Tasks::Scanners::Results::Occurrence.new(
            path: path,
            line: node.node.slice,
            pos: location.start_offset,
            line_pos: location.start_column,
            line_num: location.start_line,
            raw_key: key
          )
        ]
      end

      def full_key(controller_key, method)
        return nil if relative_key? && method[:private]
        return key unless relative_key?

        # We should handle fallback to key without method name
        [controller_key, method[:name], key].compact.join(DOT).gsub("..", ".")
      end
    end

    class PrismControllerVisitor < Prism::Visitor
      def initialize
        @controller_node_path = []
        @private_methods = false
        @methods = {}
        @before_actions = {}

        super
      end

      def controller_key
        @controller_node_path.flat_map do |node|
          case node.type
          when :module_node
            node.name.to_s.underscore
          when :class_node
            node.constant_path.child_nodes.map do |node|
              node.name.to_s.underscore.sub(/_controller\z/, '')
            end
          end
        end
      end

      def translation_calls(path)
        process_before_actions
        process_methods(path)
      end

      def visit_module_node(node)
        previous_location = @controller_node_path.last&.location
        if previous_location && previous_location.end_offset < node.location.start_offset
          @controller_node_path = [node]
        else
          @controller_node_path << node
        end

        super
      end

      def visit_class_node(node)
        @controller_node_path << node
        super
      end

      def visit_def_node(node)
        translation_calls, other_calls = node.body.child_nodes
          .filter_map {|n| visit(n) }
          .partition { |n| n.type == :translation_node }

        @methods[node.name] = {
          name: node.name,
          private: @private_methods,
          translation_calls: translation_calls,
          other_calls: other_calls
        }

        super
      end

      def visit_call_node(node)
        case node.name
        when :private
          @private_methods = true
        when :before_action
          parse_before_action(node)
        when :t, :'I18n.t', :t!, :'I18n.t!', :translate, :translate!
          key_argument, options = node.arguments.arguments
          TranslationNode.new(
            node: node,
            key: extract_value(key_argument),
            options: options
          )
        else
          node
        end
      end

      private

      def process_before_actions
        methods = @methods.values
        private_methods = methods.select { |m| m[:private] }
        non_private_methods = methods.reject { |m| m[:private] }

        @before_actions.each do |name, before_action|
          # We can only handle before_actions that are private methods
          before_action_method = private_methods.find { |m| m[:name].to_s == name }
          next if before_action_method.nil?

          methods_for_before_action(
            non_private_methods,
            before_action
          ).each do |method|
            method[:translation_calls] += before_action_method[:translation_calls]
            method[:other_calls] += before_action_method[:other_calls]
          end
        end
      end

      def process_methods(path)
        @methods.each_value do |method|
          process_method(method)
        end

        @methods.values.flat_map do |method|
          method[:translation_calls].map do |node|
            node.to_occurrence(path, controller_key, method, node)
          end.compact
        end
      end

      def process_method(method)
        return if method[:status] == :processed
        fail(ArgumentError, 'Cannot handle cyclic method calls') if method[:status] == :processing

        method[:status] = :processing

        method[:other_calls].each do |call_node|
          process_method(@methods[call_node.name])
          method[:translation_calls] += Array(@methods[call_node.name][:translation_calls])
        end

        method[:status] = :processed
      end

      def parse_before_action(node)
        arguments_node = node.arguments
        if arguments_node.arguments.empty? || arguments_node.arguments.size > 2
          fail(ArgumentError, 'Cannot handle before_action with these arguments')
        end

        name = extract_value(arguments_node.arguments[0])
        options = arguments_node.arguments.last if arguments_node.arguments.length > 1

        @before_actions[name] = {
          node: node,
          only: Array(extract_hash_value(options, :only)),
          except: Array(extract_hash_value(options, :except)),
          calls: []
        }
      end

      def extract_hash_value(node, key)
        return unless %i[keyword_hash_node hash_node].include?(node.type)

        node.elements.each do |element|
          next unless key.to_s == element.key.value.to_s

          return extract_value(element.value)
        end

        nil
      end

      def extract_value(node)
        case node.type
        when :symbol_node
          node.value.to_s
        when :string_node
          node.content
        when :array_node
          node.child_nodes.map { |child| extract_value(child) }
        else
          fail(ArgumentError, "Cannot handle node type: #{node.type}")
        end
      end

      def methods_for_before_action(methods, before_action)
        if before_action[:only].present?
          methods.select { |m| before_action[:only].include?(m[:name]) }
        elsif before_action[:except].present?
          methods.reject { |m| before_action[:except].include?(m[:name]) }
        end
      end

      def key_from_node(node)
        @matchers.each do |matcher|
          result =
            if matcher.respond_to?(:process_node)
              matcher.process_node(node)
            else
              matcher.convert_to_key_occurrences(node, nil)
            end
          next if result.nil?

          return result[0]
        end

        nil
      end

      def relative_key?(key)
        key.start_with?(DOT)
      end
    end
  end
end
