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
      @parent = opts[:parent] || first.try(:parent)
      @list.map! { |node| node.parent == @parent ? node : node.derive(parent: @parent) }
      @key_to_node = @list.inject({}) { |h, node| h[node.key] = node; h }
    end

    def attributes
      super.merge(parent: @parent)
    end

    def rename_key(key, new_key)
      node = key_to_node.delete(key)
      replace_node! node, node.derive(key: new_key)
      self
    end

    def replace_node!(node, new_node)
      @list[@list.index(node)] = new_node
      key_to_node[new_node.key] = new_node
    end

    include SplitKey

    # @return [Node] by full key
    def get(full_key)
      first_key, rest = split_key(full_key, 2)
      node            = key_to_node[first_key]
      if rest && node
        node = node.children.try(:get, rest)
      end
      node
    end

    alias [] get

    # add or replace node by full key
    def set(full_key, node)
      key_part, rest = split_key(full_key, 2)
      child = key_to_node[key_part]

      if rest
        unless child
          child = Node.new(key: key_part, parent: parent, children: [])
          append! child
        end
        if child.children
          child.children.set rest, node
        else
          raise CommandError.new("Failed to add children to #{child.full_key} because it has a value: #{child.value.inspect}")
        end
      else
        remove! child if child
        append! node
      end
      dirty!
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
      nodes = nodes.map do |node|
        raise "already has a child with key '#{node.key}'" if key_to_node.key?(node.key)
        key_to_node[node.key] = (node.parent == parent ? node : node.derive(parent: parent))
      end
      super(nodes)
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

    def set_root_key(new_key, data = nil)
      return self if empty?
      rename_key first.key, new_key
      leaves { |node| node.data.merge! data } if data
      self
    end

    class << self
      include SplitKey

      def null
        new
      end

      def build_forest(opts = {}, &block)
        opts[:nodes] ||= []
        parse_parent_opt!(opts)
        forest = Siblings.new(opts)
        block.call(forest) if block
        # forest.parent.children = forest
        forest
      end

      def from_key_attr(key_attrs, opts = {}, &block)
        build_forest(opts) { |forest|
          key_attrs.each { |(full_key, attr)|
            raise "Invalid key #{full_key.inspect}" if full_key.end_with?('.')
            node = Node.new(attr.merge(key: split_key(full_key).last))
            block.call(full_key, node) if block
            forest[full_key] = node
          }
        }
      end

      def from_key_names(keys, opts = {}, &block)
        build_forest(opts) { |forest|
          keys.each { |full_key|
            node = Node.new(key: split_key(full_key).last)
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
            siblings[full_key] = Node.new(key: split_key(full_key).last, value: value)
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
