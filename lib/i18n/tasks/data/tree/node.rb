# coding: utf-8

require 'i18n/tasks/data/tree/traversal'
require 'i18n/tasks/data/tree/siblings'
module I18n::Tasks::Data::Tree
  class Node
    include Enumerable
    include Traversal

    attr_accessor :value
    attr_reader :key, :children, :parent

    def initialize(opts = {})
      @key          = opts[:key]
      @key = @key.to_s.freeze if @key
      @value        = opts[:value]
      @data         = opts[:data]
      @parent       = opts[:parent]
      self.children = (opts[:children] if opts[:children])
    end

    def attributes
      {key: @key, value: @value, data: @data.try(:clone), parent: @parent, children: @children}
    end

    def derive(new_attr = {})
      self.class.new(attributes.merge(new_attr))
    end

    def children=(children)
      @children = case children
                    when Siblings
                      children.parent == self ? children : children.derive(parent: self)
                    when NilClass
                      nil
                    else
                      Siblings.new(nodes: children, parent: self)
                  end
      dirty!
    end

    def each(&block)
      return to_enum(:each) { 1 } unless block
      block.yield(self)
      self
    end

    def value_or_children_hash
      leaf? ? value : children.try(:to_hash)
    end

    def leaf?
      !children
    end

    # a node with key nil is considered Empty. this is to allow for using these nodes instead of nils
    def root?
      !parent?
    end

    def parent?
      !!parent
    end

    def children?
      children && children.any?
    end

    def data
      @data ||= {}
    end

    def data?
      @data.present?
    end

    def get(key)
      children.get(key)
    end

    alias [] get

    # append and reparent nodes
    def append!(nodes)
      if @children
        @children.merge!(nodes)
      else
        @children = Siblings.new(nodes: nodes, parent: self)
      end
      self
    end

    def append(nodes)
      derive.append!(nodes)
    end

    def full_key(opts = {})
      root            = opts.key?(:root) ? opts[:root] : true
      @full_key       ||= {}
      @full_key[root] ||= "#{"#{parent.full_key(root: root)}." if parent? && (root || parent.parent?)}#{key}"
    end

    def walk_to_root(&visitor)
      return to_enum(:walk_to_root) unless visitor
      visitor.yield self
      parent.walk_to_root(&visitor) if parent?
    end

    def root
      p = nil
      walk_to_root { |node| p = node }
      p
    end

    def walk_from_root(&visitor)
      return to_enum(:walk_from_root) unless visitor
      walk_to_root.reverse_each do |node|
        visitor.yield node
      end
    end

    def to_nodes
      Nodes.new([self])
    end

    def to_siblings
      parent && parent.children || Siblings.new(nodes: [self])
    end

    def to_hash(sort = false)
      (@hash ||= {})[sort] ||= begin
        children_hash = children ? children.to_hash(sort) : {}
        if key.nil?
          children_hash
        elsif leaf?
          {key => value}
        else
          {key => children_hash}
        end
      end
    end

    delegate :to_json, to: :to_hash
    delegate :to_yaml, to: :to_hash

    def inspect(level = 0)
      label = if key.nil?
                Term::ANSIColor.dark '∅'
              else
                [Term::ANSIColor.color(1 + level % 15, key),
                 (": #{Term::ANSIColor.cyan(value.to_s)}" if leaf?),
                 (" #{data}" if data?)].compact.join
              end
      ['  ' * level, label, ("\n" + children.map { |c| c.inspect(level + 1) }.join("\n") if children?)].compact.join
    end

    protected

    def dirty!
      @hash     = nil
      @full_key = nil
    end

    class << self
      # value can be a nested hash
      def from_key_value(key, value)
        Node.new(key: key.try(:to_s)).tap do |node|
          if value.is_a?(Hash)
            node.children = Siblings.from_nested_hash(value)
          else
            node.value = value
          end
        end
      end
    end
  end
end
