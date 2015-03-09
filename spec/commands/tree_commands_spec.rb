require 'spec_helper'

describe 'Tree commands' do
  delegate :run_cmd, to: :TestCodebase
  before do
    TestCodebase.setup
  end

  after do
    TestCodebase.teardown
  end

  context 'tree-merge' do
    trees = [{'a' => '1', 'b' => '2'}, {'a' => '-1', 'c' => '3'}]
    it trees.map(&:to_json).join(', ') do
      merged = JSON.parse run_cmd('tree-merge', '-fjson', '-S', *trees.map(&:to_json))
      expect(merged).to eq trees.reduce(:merge)
    end
  end

  context 'tree-filter' do
    forest  = {'a' => '1', 'b' => '2', 'c' => {'a' => '3'}}
    pattern = '{a,c.*}'
    it "-p #{pattern.inspect} #{forest.to_json}" do
      selected = JSON.parse run_cmd('tree-filter', '-fjson', '-p', pattern, forest.to_json)
      expect(selected).to eq(forest.except('b'))
    end
  end

  context 'tree-subtract' do
    trees = [{'a' => '1', 'b' => '2'}, {'a' => '-1', 'c' => '3'}]
    it trees.map(&:to_json).join(' - ') do
      subtracted = JSON.parse run_cmd('tree-subtract', '-fjson', '-S', *trees.map(&:to_json))
      expected = {'b' => '2'}
      expect(subtracted).to eq expected
    end
  end

  context 'tree-rename-key' do
    def forest
      {'a' => {'b' => {'a' => '1'}}}
    end

    def rename_key(from, to)
      JSON.parse run_cmd('tree-rename-key', '-fjson', '-k', from, '-n', to, forest.to_json)
    end

    it 'renames root node' do
      expect(rename_key('a', 'x')).to eq(forest.tap { |f| f['x'] = f.delete('a') })
    end
    it 'renames node' do
      expect(rename_key('a.b', 'x')).to eq(forest.tap { |f| f['a']['x'] = f['a'].delete('b') })
    end
    it 'renames leaf' do
      expect(rename_key('a.b.a', 'x')).to eq(forest.tap { |f| f['a']['b']['x'] = f['a']['b'].delete('a') })
    end
  end

  context 'tree-convert' do
    def forest
      {'x' => '1', 'a' => {'b' => {'a' => '2'}}}
    end

    it 'converts to keys' do
      keys = run_cmd('tree-convert', '-fjson', '-tkeys', forest.to_json).split("\n")
      expect(keys.sort).to eq(['a.b.a', 'x'].sort)
    end
  end
end
