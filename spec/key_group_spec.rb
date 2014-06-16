# coding: utf-8
require 'spec_helper'

describe 'KeyGroup' do
  def key_group(group, attr = {})
    ::I18n::Tasks::KeyGroup.new(group, attr)
  end

  let!(:kg_attr) { { a: :b, x: '0' } }
  let!(:kg) { key_group %w(a b), kg_attr }

  it('#attr') { expect(kg.attr).to eq kg_attr }

  it '#to_a' do
    expect(kg.to_a).to eq [
        {key: 'a'}.merge(kg_attr),
        {key: 'b'}.merge(kg_attr)
    ]
  end

  it '#merge' do
    kg2_attr = {a: :b, x: '1', c: :d}
    kg2 = key_group %w(c), kg2_attr
    kg3 = key_group [{key: 'd', prop: true}]
    expect([kg, kg2, kg3].reduce(:+).to_a).to eq [
        {key: 'a'}.merge(kg_attr),
        {key: 'b'}.merge(kg_attr),
        {key: 'c'}.merge(kg2_attr),
        {key: 'd', prop: true}
    ]
  end

  it '#merge shared attr' do
    kg2 = key_group %w(c d), kg_attr
    expect((kg + kg2).keys[0].own_attr).to eq kg.keys[0].own_attr
  end

  it '#sort!' do
    kg = key_group [{key: 'a', prop: '0'}, {key: 'b', prop: '1'}]
    kg.sort! { |a, b| b[:prop] <=> a[:prop] }
    expect(kg.keys[0][:prop]).to eq '1'
  end

  it '#sort_by_attr!' do
    expect(key_group(%w(a b c)).tap { |kg|
      kg.sort_by_attr!(key: :desc)
    }.keys.map(&:key)).to eq %w(c b a)
  end
end
