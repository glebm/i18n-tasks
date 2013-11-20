module I18n::Tasks::DataTraversal
  # translation of the key found in the passed hash or nil
  # @return [String,nil]
  def t(hash, key)
    key.split('.').inject(hash) { |r, seg| r[seg] if r }
  end

  # traverse hash, yielding with full key and value
  # @param hash [Hash{String => String,Hash}] translation data to traverse
  # @yield [full_key, value] yields full key and value for every translation in #hash
  # @return [nil]
  def traverse(path = '', hash)
    q = [[path, hash]]
    until q.empty?
      path, value = q.pop
      if value.is_a?(Hash)
        value.each { |k, v| q << ["#{path}.#{k}", v] }
      else
        yield path[1..-1], value
      end
    end
  end

  def list_to_tree(list)
    list = list.sort
    tree = {}
    list.each do |key, value|
      key_segments = key.to_s.split('.')
      node = key_segments[0..-2].inject(tree) do |r, segment|
        if r.key?(segment)
          r[segment]
        else
          r[segment] = {}
        end
      end
      node[key_segments.last] = value
    end
    tree
  end
end