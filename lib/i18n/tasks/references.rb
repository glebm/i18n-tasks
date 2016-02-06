# frozen_string_literal: true
module I18n::Tasks
  module References
    # Given a raw usage tree and a tree of reference keys in the data, return 3 trees:
    # 1. Raw references -- a subset of the usages tree with keys that are reference key usages.
    # 2. Resolved references -- all the used references in their fully resolved form.
    # 3. Reference keys -- all the used reference keys.
    def process_references(usages, data_references = merge_reference_trees(data_forest.select_keys { |_, node| node.reference? }))
      fail ArgumentError.new('usages must be a Data::Tree::Instance') unless usages.is_a?(Data::Tree::Siblings)
      fail ArgumentError.new('all_references must be a Data::Tree::Instance') unless data_references.is_a?(Data::Tree::Siblings)
      raw_refs      = empty_forest
      resolved_refs = empty_forest
      refs          = empty_forest
      data_references.key_to_node.each do |ref_key_part, ref_node|
        usages.each do |usage_node|
          next unless usage_node.key == ref_key_part
          if ref_node.leaf?
            unless refs.key_to_node.key?(ref_node.key)
              refs.merge_node!(Data::Tree::Node.new(key: ref_node.key, data: usage_node.data))
            end
            resolved_refs.merge!(
                Data::Tree::Siblings.from_key_names([ref_node.value.to_s]) { |_, resolved_node|
                  raw_refs.merge_node!(usage_node)
                  if usage_node.leaf?
                    resolved_node.data.merge!(usage_node.data)
                  else
                    resolved_node.children = usage_node.children
                  end
                  resolved_node.leaves { |node| node.data[:ref_info] = [ref_node.full_key, ref_node.value.to_s] }
                }.tap { |new_resolved_refs|
                  refs.key_to_node[ref_node.key].data.tap { |ref_data|
                    ref_data[:occurrences] ||= []
                    new_resolved_refs.leaves { |leaf| ref_data[:occurrences].concat(leaf.data[:occurrences] || []) }
                    ref_data[:occurrences].sort_by!(&:path)
                    ref_data[:occurrences].uniq!
                  }
                })
          else
            child_raw_refs, child_resolved_refs, child_refs = process_references(usage_node.children, ref_node.children)
            raw_refs.merge_node! Data::Tree::Node.new(key: ref_node.key, children: child_raw_refs) unless child_raw_refs.empty?
            resolved_refs.merge! child_resolved_refs
            refs.merge_node! Data::Tree::Node.new(key: ref_node.key, children: child_refs) unless child_refs.empty?
          end
        end
      end
      [raw_refs, resolved_refs, refs]
    end

    # Given a forest of references, merge trees into one tree, ensuring there are no conflicting references.
    # @param roots [Data::Tree::Siblings]
    # @return [Data::Tree::Siblings]
    def merge_reference_trees(roots)
      roots.inject(empty_forest) do |forest, root|
        root.keys { |full_key, node|
          log_warn(
              "Self-referencing key #{node.full_key(root: false).inspect} in #{node.data[:locale].inspect}"
          ) if full_key == node.value.to_s
        }
        forest.merge!(
            root.children,
            on_leaves_merge: -> (node, other) {
              log_warn(
                  "Conflicting references: #{node.full_key(root: false)} ⮕ #{node.value} in #{node.data[:locale]}, but ⮕ #{other.value} in #{other.data[:locale]}"
              ) if node.value != other.value
            })
      end
    end
  end
end
