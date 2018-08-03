# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tree commands' do
  delegate :run_cmd, to: :TestCodebase
  before do
    TestCodebase.setup
  end

  after do
    TestCodebase.teardown
  end

  context 'tree-merge' do
    trees = [{ 'a' => '1', 'b' => '2' }, { 'a' => '-1', 'c' => '3' }]
    it trees.map(&:to_json).join(', ') do
      merged = JSON.parse run_cmd('tree-merge', '-fjson', '-S', *trees.map(&:to_json))
      expect(merged).to eq trees.reduce(:merge)
    end
  end

  context 'tree-filter' do
    forest = { 'a' => '1', 'b' => '2', 'c' => { 'a' => '3' } }
    pattern = '{a,c.*}'
    it "-p #{pattern.inspect} #{forest.to_json}" do
      selected = JSON.parse run_cmd('tree-filter', '-fjson', '-p', pattern, forest.to_json)
      expect(selected).to eq(forest.except('b'))
    end
  end

  context 'tree-subtract' do
    trees = [{ 'a' => '1', 'b' => '2' }, { 'a' => '-1', 'c' => '3' }]
    it trees.map(&:to_json).join(' - ') do
      subtracted = JSON.parse run_cmd('tree-subtract', '-fjson', '-S', *trees.map(&:to_json))
      expected = { 'b' => '2' }
      expect(subtracted).to eq expected
    end
  end

  context 'tree-mv' do
    def tree_mv(from, to, forest, all_locales: false)
      output = run_cmd('tree-mv', *(['-a'] if all_locales), '-fyaml', from, to, forest.to_yaml.sub(/\A---\n/, ''))
      YAML.load(output)
    end

    it 'merge-moves multiple nodes' do
      forest = {
        'en' => {
          'user' => {
            'greeting' => 'Hello, %{user}!'
          },
          'profile' => {
            'page_title' => 'My account'
          }
        }
      }
      expected = {
        'en' => {
          'account' => {
            'greeting' => 'Hello, %{user}!',
            'page_title' => 'My account'
          }
        }
      }
      expect(tree_mv('en.{user,profile}', 'en.account', forest)).to eq expected
      expect(tree_mv('{user,profile}', 'account', forest, all_locales: true)).to eq expected
    end

    it 'collapses emptied nodes' do
      forest = {
        'en' => {
          'a' => { 'b' => { 'c' => 'm' } }
        }
      }
      expected = {
        'en' => {
          'z' => 'm'
        }
      }
      expect(tree_mv('en.a.b.c', 'en.z', forest)).to eq expected
      expect(tree_mv('a.b.c', 'z', forest, all_locales: true)).to eq expected
    end

    it 'removes nodes if target pattern is empty' do
      forest = {
        'en' => {
          'a' => 'x',
          'b' => 'x',
          'c' => 'x'
        }
      }
      expected = {
        'en' => {
          'c' => 'x'
        }
      }
      expect(tree_mv('en.{a,b}', 'en', forest)).to eq expected
      expect(tree_mv('{a,b}', '', forest, all_locales: true)).to eq expected
    end

    it 'renames in multiple root nodes' do
      forest = {
        'en' => {
          'a' => { 'm' => 'EN1' }
        },
        'es' => {
          'a' => { 'm' => 'ES1' },
          'b' => { 'merge' => 'ES2' }
        }
      }
      expected = {
        'en' => {
          'b' => {
            'm' => 'EN1'
          }
        },
        'es' => {
          'b' => {
            'merge' => 'ES2',
            'm' => 'ES1'
          }
        }
      }
      expect(tree_mv('{:}.a.{:}', '\1.b.\2', forest)).to eq expected
      expect(tree_mv('a.{:}', 'b.\1', forest, all_locales: true)).to eq expected
    end

    it 'adjusts references' do
      forest = {
        'en' => {
          'a' => :b,
          'b' => 'x'
        }
      }
      expected = {
        'en' => {
          'a' => :b2,
          'b2' => 'x'
        }
      }
      expect(tree_mv('en.b', 'en.b2', forest)).to eq expected
      expect(tree_mv('b', 'b2', forest, all_locales: true)).to eq expected
    end
  end

  context 'tree-convert' do
    def forest
      { 'x' => '1', 'a' => { 'b' => { 'a' => '2' } } }
    end

    it 'converts to keys' do
      keys = run_cmd('tree-convert', '-fjson', '-tkeys', forest.to_json).split("\n")
      expect(keys.sort).to eq(['a.b.a', 'x'].sort)
    end
  end
end
