# coding: utf-8
module Trees
  def expect_node_key_data(node, key, data)
    expect(node.full_key(root: false)).to eq key
    expect(node.data).to eq data
  end

  def build_tree(hash)
    I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
  end
end
