# frozen_string_literal: true

module Trees
  def expect_node_key_data(node, key, data)
    expect(node.full_key(root: false)).to eq key
    expect(node.data).to eq adjust_occurrences(data)
  end

  def build_tree(hash)
    I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
  end

  def build_node(attr = {})
    fail 'invalid node (more than 1 root)' if attr.size > 1

    key, value = attr.first
    I18n::Tasks::Data::Tree::Node.from_key_value(key, value)
  end

  def new_node(**attr)
    I18n::Tasks::Data::Tree::Node.new(**attr)
  end
end
