module Trees
  def build_tree(hash)
    I18n::Tasks::Data::Tree::Siblings.from_nested_hash(hash)
  end
end
