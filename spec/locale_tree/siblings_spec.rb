# coding: utf-8
require 'spec_helper'

describe 'Tree siblings / forest' do

  context 'a tree' do
    let(:a_hash) { {a: 1, b: {ba: 1, bb: 2}}.deep_stringify_keys }

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
      a = build_tree(a_hash)
      b_hash = {b: {bc: 1}, c: 1}.deep_stringify_keys
      expect(a.merge(build_tree(b_hash)).to_hash).to eq(a_hash.deep_merge(b_hash))
    end
  end
end
