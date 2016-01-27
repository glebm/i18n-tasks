# frozen_string_literal: true
module I18n::Tasks
  module References
    # Given a tree of key usages, return all the reference keys in the tree in their resolved form.
    # @param usages [Data::Tree::Siblings]
    # @param references [Data::Tree::Siblings]
    # @return [Array<String>] a list of all references and their resolutions.
    def resolve_references(usages, references)
      usages.each.flat_map do |node|
        references.key_to_node.flat_map do |ref_key_part, ref_node|
          if node.key == ref_key_part
            if ref_node.leaf?
              [ref_node.full_key(root: false)] +
                  if node.leaf?
                    [ref_node.value.to_s]
                  else
                    node.children.flat_map { |child|
                      collect_referenced_keys(child, [ref_node.value.to_s])
                    }
                  end
            else
              resolve_references(node.children, ref_node.children)
            end
          else
            []
          end
        end
      end
    end

    # Given a node, return the keys of all the leaves up to the given node prefixed with the given prefix.
    # @param node [Data::Tree::Node]
    # @param prefix [Array<String>]
    # @return Array<String> full keys
    def collect_referenced_keys(node, prefix)
      if node.leaf?
        (prefix + [node.key]) * '.'
      else
        node.children.flat_map { |child| collect_referenced_keys(child, prefix + [node.key]) }
      end
    end

    # Given a forest of references, merge trees into one tree, ensuring there are no conflicting references.
    # @param roots [Data::Tree::Siblings]
    # @return [Data::Tree::Siblings]
    def merge_reference_trees(roots)
      roots.inject(empty_forest) do |forest, root|
        root.keys { |full_key, node|
          ::I18n::Tasks::Logging.log_warn(
              "Self-referencing node: #{node.full_key.inspect} is #{node.value.inspect} in #{node.data[:locale]}"
          ) if full_key == node.value.to_s
        }
        forest.merge!(
            root.children,
            leaves_merge_guard: -> (node, other) {
              ::I18n::Tasks::Logging.log_warn(
                  "Conflicting references: #{node.full_key.inspect} is #{node.value.inspect} in #{node.data[:locale]}, but #{other.value.inspect} in #{other.data[:locale]}"
              ) if node.value != other.value
            })
      end
    end
  end
end
