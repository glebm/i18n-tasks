# coding: utf-8
module I18n::Tasks::Data::Tree
  # Any Enumerable that yields nodes can mix in this module
  module Traversal

    def nodes(&block)
      depth_first(&block)
    end

    def leaves(&visitor)
      return to_enum(:leaves) unless visitor
      nodes do |node|
        visitor.yield(node) if node.leaf?
      end
      self
    end

    def levels(&block)
      return to_enum(:levels) unless block
      nodes    = to_nodes
      non_null = nodes.reject(&:null?)
      unless non_null.empty?
        block.yield non_null
        Nodes.new(nodes.children).levels(&block)
      end
      self
    end

    def breadth_first(&visitor)
      return to_enum(:breadth_first) unless visitor
      levels do |nodes|
        nodes.each { |node| visitor.yield(node) unless node.null? }
      end
      self
    end

    def depth_first(&visitor)
      return to_enum(:depth_first) unless visitor
      each { |node|
        visitor.yield node unless node.null?
        node.children.each do |child|
          child.depth_first(&visitor)
        end if node.children?
      }
      self
    end

    # @option root include root in full key
    def keys(key_opts = {}, &visitor)
      key_opts[:root] = false unless key_opts.key?(:root)
      return to_enum(:keys, key_opts) unless visitor
      leaves { |node| visitor.yield(node.full_key(key_opts), node) }
      self
    end


    def key_names(opts = {})
      opts[:root] = false unless opts.key?(:root)
      keys(opts).map { |key, _node| key }
    end

    def key_values(opts = {})
      opts[:root] = false unless opts.key?(:root)
      keys(opts).map { |key, node| [key, node.value] }
    end

    def root_key_values
      keys(root: false).map { |key, node| [node.root.key, key, node.value]}
    end

    #-- modify / derive

    # @return Siblings
    def select_nodes(&block)
      tree = Siblings.new
      each do |node|
        if block.yield(node)
          tree.append! node.derive(
              parent: tree.parent,
              children: (node.children.select_nodes(&block).to_a if node.children)
          )
        end
      end
      tree
    end

    # @return Siblings
    def select_keys(opts = {}, &block)
      root = opts.key?(:root) ? opts[:root] : false
      ok   = {}
      keys(root: root) do |full_key, node|
        if block.yield(full_key, node)
          node.walk_to_root { |p|
            break if ok[p]
            ok[p] = true
          }
        end
      end
      select_nodes { |node|
        ok[node]
      }
    end


    # @return Siblings
    def intersect_keys(other_tree, key_opts = {}, &block)
      if block
        select_keys(key_opts) { |key, node|
          other_node = other_tree[key]
          other_node && block.call(key, node, other_node)
        }
      else
        select_keys(key_opts) { |key, node| other_tree[key] }
      end
    end

    def grep_keys(match, opts = {})
      select_keys(opts) do |full_key, _node|
        match === full_key
      end
    end
  end
end
