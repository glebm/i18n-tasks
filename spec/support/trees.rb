# frozen_string_literal: true

module Trees
  def expect_node_key_data(node, key, data)
    expect(node.full_key(root: false)).to eq key
    expected_data = adjust_occurrences(data)
    expected_occurrences = expected_data[:occurrences]
    actual_occurrences = node.data[:occurrences]
    if expected_occurrences && actual_occurrences
      expected_occurrences.zip(actual_occurrences).each do |expected, actual|
        expected.instance_variable_set(:@plural, actual.plural) if expected.plural.nil?
      end
    end
    expect(node.data).to eq expected_data
  end

  def build_tree(hash)
    I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
  end

  def build_node(attr = {})
    fail "invalid node (more than 1 root)" if attr.size > 1

    key, value = attr.first
    I18n::Tasks::Data::Tree::Node.from_key_value(key, value)
  end

  def new_node(**attr)
    I18n::Tasks::Data::Tree::Node.new(**attr)
  end
end
