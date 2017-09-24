# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SplitKey' do
  include ::I18n::Tasks::SplitKey

  [
    # rubocop:disable Lint/InterpolationCheck
    ['', %w[]],
    ['a', %w[a]],
    ['a.b', %w[a b]],
    ['a.b.', %w[a b]],
    ['a.b.c', %w[a b c]],
    ['a.#{b.c}', %w[a #{b.c}]],
    ['a.#{b.c}.', %w[a #{b.c}]],
    ['a.#{b.c}.d', %w[a #{b.c} d]],
    ['a.#{b.c}.d.[e.f]', %w(a #{b.c} d [e.f])]
    # rubocop:enable Lint/InterpolationCheck
  ].each do |(arg, ret)|
    it "#{arg} is split into #{ret.inspect}" do
      expect(split_key(arg)).to eq(ret)
    end
  end

  it 'limits results to second argument' do
    expect(split_key('a.b.c', 1)).to eq(['a.b.c'])
    expect(split_key('a.b.c', 2)).to eq(['a', 'b.c'])
    expect(split_key('a.b.c.', 2)).to eq(['a', 'b.c.'])
    expect(split_key('a.b.c.d.e.f', 4)).to eq(['a', 'b', 'c', 'd.e.f'])
  end

  it 'last part' do
    expect(last_key_part('a.b.c')).to eq('c')
    expect(last_key_part('a')).to eq('a')
    expect(last_key_part('a.b.c.d')).to eq('d')
  end
end
