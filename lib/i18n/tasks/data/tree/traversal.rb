# coding: utf-8
module I18n::Tasks::Data::Tree
  # Any Enumerable that yields nodes can mix in this module
  module Traversal

    def nodes(&block)
      walk_depth_first(&block)
    end

    def leaves(&visitor)
      return to_enum(:leaves) unless visitor
      nodes do |node|
        visitor.yield(node) if node.leaf?
      end
    end

    # @param root include root in full key
    def keys(opts = {}, &visitor)
      root = opts.key?(:root) ? opts[:root] : true
      return to_enum(:keys, root: root) unless visitor
      leaves { |node| visitor.yield(node.full_key(root: root), node) }
    end

    def levels(&block)
      return to_enum(:levels) unless block
      nodes    = to_nodes
      non_null = nodes.reject(&:null?)
      unless non_null.empty?
        block.yield non_null
        Nodes.new(nodes.children).levels(&block)
      end
    end

    def walk_breadth_first(&visitor)
      return to_enum(:walk_breadth_first) unless visitor
      levels do |nodes|
        nodes.each { |node| visitor.yield(node) unless node.null? }
      end
    end

    def walk_depth_first(&visitor)
      return to_enum(:walk_depth_first) unless visitor
      each { |node|
        visitor.yield node unless node.null?
        node.children.each do |child|
          child.walk_depth_first(&visitor)
        end if node.children?
      }
    end

    #-- modify / derive

    # @return Siblings
    def select_nodes(&block)
      result = Node.new(children: [])
      each do |node|
        if block.yield(node)
          result.append!(
              node.derive(
                  parent:   result  ,
                  children: (node.children.select_nodes(&block) if node.children)
              )
          )
        end
      end
      result.children
    end

    # @return Siblings
    def select_keys(opts = {}, &block)
      root = opts.key?(:root) ? opts[:root] : true
      ok = {}
      keys(root: root) do |full_key, node|
        if block.yield(full_key, node)
          node.walk_to_root { |p|
            break if ok[p]
            ok[p] = true
          }
        end
      end
      select_nodes { |node| ok[node] }
    end
  end
end
