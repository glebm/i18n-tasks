# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tree siblings / forest' do
  context 'Node' do
    it '::new with children' do
      children = I18n::Tasks::Data::Tree::Siblings.from_key_attr([['a', { value: 1 }]])
      node = new_node(
        key: 'fr',
        children: children
      )
      expect(node.to_siblings.first.children.parent.key).to eq 'fr'
    end

    it '== (false by value)' do
      expect(build_node('a' => { 'b' => { 'c' => 1 } })).to_not(
        eq(build_node('a' => { 'b' => { 'c' => 2 } }))
      )
    end

    it '== (false by key)' do
      expect(build_node('a' => { 'b' => { 'c' => 1 } })).to_not(
        eq(build_node('a' => { 'b' => { 'd' => 1 } }))
      )
    end

    it '== (false by children)' do
      expect(build_node('a' => { 'b' => { 'c' => 1 } })).to_not(
        eq(build_node('a' => { 'b' => { 'c' => 1 }, 'x' => 2 }))
      )
    end

    it '== (true)' do
      expect(build_node('a' => { 'b' => { 'c' => 1 }, 'x' => 2 })).to_not(
        eq(build_node('a' => { 'b' => { 'd' => 1 }, 'x' => 2 }))
      )
    end
  end

  context 'a tree' do
    let(:a_hash) { { 'a' => 1, 'b' => { 'ba' => 1, 'bb' => 2 } } }

    it '::from_nested_hash' do
      a = build_tree(a_hash)
      expect(a.to_hash).to eq(a_hash)
    end

    it '#derive' do
      a = build_tree(a_hash)
      b = a.derive.append! build_tree(c: 1)

      # a was not modified
      expect(a.to_hash).to eq(a_hash)
      # but b was
      expect(b.to_hash).to eq(a_hash.merge('c' => 1))
    end

    it '#merge' do
      a      = build_tree(a_hash)
      b_hash = { 'b' => { 'bc' => 1 }, 'c' => 1 }
      expect(a.merge(build_tree(b_hash)).to_hash).to eq(a_hash.deep_merge(b_hash))
    end

    it '#merge does not modify self' do
      a = build_tree(a: 1)
      b = build_tree(a: 2)
      c = a.merge b
      expect(a['a'].value).to eq 1
      expect(c['a'].value).to eq 2
      expect(b['a'].value).to eq 2
    end

    it '#merge conflict value <- scope' do
      a = build_tree(a: 1)
      b = build_tree(a: { b: 1 })
      expect { silence_stderr { a.merge(b) } }.to_not raise_error
      expect(capture_stderr { a.merge(b) })
        .to include("[WARN] 'a' was a leaf, now has children (value <- scope conflict)")
    end

    it '#merge does not warn about conflict with Unicode CLDR category leaves' do
      a = build_tree(a: 1)
      b = build_tree(a: { zero: 0, one: 1, two: 2, few: 7, many: 88, other: 'ok' })
      expect(capture_stderr { a.merge(b) }).to be_empty
    end

    it '#merge warns about conflict with Unicode CLDR category internal nodes' do
      a = build_tree(a: 1)
      b = build_tree(a: { one: { foo: 1, bar: 2 } })
      expect(capture_stderr { a.merge(b) })
        .to include("[WARN] 'a' was a leaf, now has children (value <- scope conflict)")
    end

    it '#set conflict value <- scope' do
      a = build_tree(a: 1)
      expect { silence_stderr { a.set('a.b', new_node(key: 'b', value: 1)) } }.to_not raise_error
    end

    it '#intersect' do
      x = { a: 1, b: { ba: 1, bb: 2 } }
      y = { b: { ba: 1, bc: 3 }, c: 1 }
      intersection = { 'b' => { 'ba' => 1 } }
      a = build_tree(x)
      b = build_tree(y)
      expect(a.intersect_keys(b, root: true).to_hash).to eq(intersection)
    end

    it '#select_keys' do
      expect(build_tree(a: 1, b: 1).select_keys { |k, _node| k == 'b' }.to_hash).to eq('b' => 1)
    end

    it '#append!' do
      expect(build_tree('a' => 1).append!(new_node(key: 'b', value: 2)).to_hash).to eq('a' => 1, 'b' => 2)
    end

    it '#set replace value' do
      expect(build_tree(a: { b: 1 }).tap { |t| t['a.b'] = new_node(key: 'b', value: 2) }.to_hash).to(
        eq('a' => { 'b' => 2 })
      )
    end

    it '#set get' do
      t = build_tree(a: { x: 1 })
      node = new_node(key: 'd', value: 'e')
      t["a.b.c.#{node.key}"] = node
      expect(t['a.b.c.d'].value).to eq('e')
    end

    it '#inspect' do
      expect(build_tree(a_hash).inspect).to eq "a: 1\nb\n  ba: 1\n  bb: 2"
      expect(build_tree({}).inspect).to eq '{∅}'
    end
  end
end
