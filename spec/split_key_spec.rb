require 'spec_helper'

describe 'SplitKey' do
  include SplitKey

  [['', %w()],
   ['a', %w(a)],
   ['a.b', %w(a b)],
   ['a.b.', %w(a b)],
   ['a.b.c', %w(a b c)],
   ['a.#{b.c}', %w(a #{b.c})],
   ['a.#{b.c}.', %w(a #{b.c})],
   ['a.#{b.c}.d', %w(a #{b.c} d)],
   ['a.#{b.c}.d.[e.f]', %w(a #{b.c} d [e.f])],
  ].each do |(arg, ret)|
    it "#{arg} is split into #{ret.inspect}" do
      expect(split_key arg).to eq(ret)
    end
  end

  it 'limits results to second argument' do
    expect(split_key 'a.b.c', 1).to eq(['a.b.c'])
    expect(split_key 'a.b.c', 2).to eq(['a', 'b.c'])
    expect(split_key 'a.b.c.', 2).to eq(['a', 'b.c.'])
  end

end
