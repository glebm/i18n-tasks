# frozen_string_literal: true

require "prism/visitor"

# This class is used to parse the arguments to e.g. a Prism::CallNode and return the values we need
# for turning them into translations and occurrences.
# Used in the PrismScanners::Visitor class.
module I18n::Tasks::Scanners::PrismScanners
  class ArgumentsVisitor < Prism::Visitor
    def visit_keyword_hash_node(node)
      node.child_nodes.each_with_object({}) do |child, hash|
        next if child.type == :assoc_splat_node

        hash[visit(child.key)] = visit(child.value)
        hash
      end
    end

    def visit_local_variable_read_node(node)
      # Keep this node to know that we cannot resolve this argument statically
      node
    end

    def visit_constant_read_node(node)
      # Keep this node to know that we cannot resolve this argument statically
      node
    end

    # Cannot handle arguments that are calls
    def visit_call_node(_node)
      nil
    end

    def visit_symbol_node(node)
      node.value
    end

    def visit_string_node(node)
      node.content
    end

    # Interpolated nodes (e.g. `Product.human_attribute_name("status.#{status}")`) contain dynamic content that cannot
    # be statically resolved. Return nil so process_arguments compacts them away and the call is skipped.
    def visit_interpolated_string_node(_node)
      nil
    end

    def visit_interpolated_symbol_node(_node)
      nil
    end

    def visit_interpolated_x_string_node(_node)
      nil
    end

    def visit_array_node(node)
      node.child_nodes.map { |child| visit(child) }
    end

    def visit_arguments_node(node)
      node.child_nodes.map { |child| visit(child) }
    end

    def visit_integer_node(node)
      node.value
    end

    def visit_lambda_node(node)
      node
    end
  end
end
