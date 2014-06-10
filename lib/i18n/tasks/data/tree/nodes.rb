# coding: utf-8

require 'i18n/tasks/data/tree/traversal'
module I18n::Tasks::Data::Tree
  # A list of nodes
  class Nodes
    attr_reader :list

    def initialize(opts = {})
      @list = opts[:nodes] ? opts[:nodes].to_a.clone : []
    end

    delegate :each, :present?, :empty?, :blank?, :size, :to_a, to: :@list
    include Enumerable
    include Traversal

    def to_nodes
      self
    end

    def attributes
      {nodes: @list}
    end

    def derive(new_attr = {})
      attr = attributes.merge(new_attr)
      attr[:nodes] ||= @list.map(&:derive)
      self.class.new(attr)
    end

    def to_hash
      @hash ||= map(&:to_hash).reduce(:deep_merge!) || {}
    end

    delegate :to_json, to: :to_hash
    delegate :to_yaml, to: :to_hash

    def inspect
      if present?
        map(&:inspect) * "\n"
      else
        Term::ANSIColor.dark '∅'
      end
    end

    # methods below change state

    def remove!(node)
      @list.delete(node) or raise "#{node.full_key} not found in #{self.inspect}"
      dirty!
      self
    end

    def append!(other)
      @list += other.to_a
      dirty!
      self
    end

    def append(other)
      derive.append!(other)
    end

    alias << append

    def merge!(nodes)
      @list += nodes.to_a
      dirty!
      self
    end
    alias + merge!

    def children(&block)
      return to_enum(:children) { map { |c| c.children.size }.reduce(:+) } unless block
      each do |node|
        node.children.each(&block) if node.children?
      end
    end

    alias children? any?

    protected
    def dirty!
      @hash = nil
    end
  end
end
