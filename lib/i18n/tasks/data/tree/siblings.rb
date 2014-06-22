# coding: utf-8

require 'i18n/tasks/data/tree/traversal'
require 'i18n/tasks/data/tree/nodes'
module I18n::Tasks::Data::Tree
  # Siblings represents a subtree sharing a common parent
  # in case of an empty parent (nil) it represents a forest
  # siblings' keys are unique
  class Siblings < Nodes
    attr_reader :parent, :key_to_node

    def initialize(opts = {})
      super(nodes: opts[:nodes])
      @key_to_node = siblings.inject({}) { |h, node| h[node.key] = node; h }
      @parent      = first.try(:parent)
      self.parent  = opts[:parent] || @parent || Node.null
    end

    def attributes
      super.merge(parent: @parent)
    end

    def parent=(node)
      return if @parent == node
      each { |root| root.parent = node }
      @parent = node
    end

    def siblings(&block)
      each(&block)
      self
    end

    # @return [Node] by full key
    def get(full_key)
      first_key, rest = full_key.to_s.split('.', 2)
      node            = key_to_node[first_key]
      if rest && node
        node = node.children.try(:get, rest)
      end
      node
    end

    alias [] get

    # add or replace node by full key
    def set(full_key, node)
      key_part, rest = full_key.split('.', 2)
      child          = key_to_node[key_part]
      if rest
        unless child
          child = Node.new(key: key_part)
          append! child
        end
        child.children ||= []
        child.children.set rest, node
        dirty!
      else
        remove! child if child
        append! node
      end
      node
    end

    alias []= set


    # methods below change state

    def remove!(node)
      super
      key_to_node.delete(node.key)
      self
    end

    def append!(nodes)
      nodes.each do |node|
        raise "node '#{node.full_key}' already has a child with key '#{node.key}'" if key_to_node.key?(node.key)
        key_to_node[node.key] = node
        node.parent           = parent
      end
      super
      self
    end

    def append(nodes)
      derive.append!(nodes)
    end

    def merge!(nodes)
      nodes = Siblings.from_nested_hash(nodes) if nodes.is_a?(Hash)
      nodes.each do |node|
        if key_to_node.key?(node.key)
          our = key_to_node[node.key]
          next if our == node
          our.value = node.value if node.leaf?
          our.data.merge!(node.data) if node.data?
          our.children.merge!(node.children) if node.children?
        else
          key_to_node[node.key] = node.derive(parent: parent)
        end
      end
      @list = key_to_node.values
      dirty!
      self
    end

    def merge(nodes)
      derive.merge!(nodes)
    end

    def key_renamed(new_name, old_name)
      node = key_to_node.delete old_name
      key_to_node[new_name] = node
    end

    class << self
      def null
        new
      end

      def build_forest(opts = {}, &block)
        opts[:nodes] ||= []
        parse_parent_opt!(opts)
        forest = Siblings.new(opts)
        block.call(forest) if block
        forest.parent.children = forest
      end

      def from_key_attr(key_attrs, opts = {}, &block)
        build_forest(opts) { |forest|
          key_attrs.each { |(full_key, attr)|
            raise "Invalid key #{full_key.inspect}" if full_key.end_with?('.')
            node = Node.new(attr.merge(key: full_key.split('.').last))
            block.call(full_key, node) if block
            forest[full_key] = node
          }
        }
      end

      def from_key_names(keys, opts = {}, &block)
        build_forest(opts) { |forest|
          keys.each { |full_key|
            node = Node.new(key: full_key.split('.').last)
            block.call(full_key, node) if block
            forest[full_key] = node
          }
        }
      end

      # build forest from nested hash, e.g. {'es' => { 'common' => { name => 'Nombre', 'age' => 'Edad' } } }
      # this is the native i18n gem format
      def from_nested_hash(hash, opts = {})
        parse_parent_opt!(opts)
        opts[:nodes] = hash.map { |key, value| Node.from_key_value key, value }
        Siblings.new(opts)
      end

      alias [] from_nested_hash

      # build forest from [[Full Key, Value]]
      def from_flat_pairs(pairs)
        Siblings.new.tap do |siblings|
          pairs.each { |full_key, value|
            siblings[full_key] = Node.new(key: full_key.split('.')[-1], value: value)
          }
        end
      end

      private
      def parse_parent_opt!(opts)
        opts[:parent] = Node.new(key: opts[:parent_key]) if opts[:parent_key]
        opts[:parent] = Node.new(opts[:parent_attr]) if opts[:parent_attr]
        opts[:parent] = Node.new(key: opts[:parent_locale], data: {locale: opts[:parent_locale]}) if opts[:parent_locale]
        opts[:parent] ||= Node.null
      end
    end
  end
end
