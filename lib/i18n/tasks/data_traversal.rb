module I18n::Tasks::DataTraversal
  # translation of the key found in the passed hash or nil
  # @return [String,nil]
  def t(key, locale = base_locale)
    key.to_s.split('.').inject(self.data[locale]) { |r, seg| r[seg] if r }
  end

  def t_proc(locale = base_locale)
    proc { |k| t(k, locale) }
  end

  # traverse => map if yield(k, v)
  def traverse_map_if(hash)
    list = []
    traverse hash do |k, v|
      mapped = yield(k, v)
      list << mapped if mapped
    end
    list
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

  # [[key, value], ...] list to tree
  def list_to_tree(list)
    list = list.sort
    tree = {}
    list.each do |key, value|
      key_segments            = key.to_s.split('.')
      node                    = key_segments[0..-2].inject(tree) do |r, segment|
        r[segment] ||= {}
      end
      node[key_segments.last] = value
    end
    tree
  end
end
