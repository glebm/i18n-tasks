# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reference keys' do
  let(:task) { ::I18n::Tasks::BaseTask.new }

  describe '#process_references' do
    it 'resolves plain references' do
      result = task.process_references(
        build_tree(
          'reference' => nil,
          'not-a-reference' => nil
        ),
        build_tree(
          'reference' => :resolved
        )
      )
      expect(result.map(&:to_hash)).to(
        eq [{ 'reference' => nil },
            { 'resolved' => nil },
            { 'reference' => nil }]
      )
    end

    it 'resolves nested references' do
      result = task.process_references(
        build_tree(
          'reference' => { 'a' => nil, 'b' => { 'c' => nil } },
          'not-a-reference' => nil
        ),
        build_tree(
          'reference' => :resolved
        )
      )
      expect(result.map(&:to_hash)).to(
        eq [{ 'reference' => { 'a' => nil, 'b' => { 'c' => nil } } },
            { 'resolved' => { 'a' => nil, 'b' => { 'c' => nil } } },
            { 'reference' => nil }]
      )
    end

    it 'resolves nested references with nested keys' do
      result = task.process_references(
        build_tree(
          'nested' => { 'reference' => { 'a' => nil, 'b' => { 'c' => nil } } },
          'not-a-reference' => nil
        ),
        build_tree(
          'nested' => { 'reference' => :resolved }
        )
      )
      expect(result.map(&:to_hash)).to(
        eq [{ 'nested' => { 'reference' => { 'a' => nil, 'b' => { 'c' => nil } } } },
            { 'resolved' => { 'a' => nil, 'b' => { 'c' => nil } } },
            { 'nested' => { 'reference' => nil } }]
      )
    end

    it 'resolves nested references with nested keys and nested reference targets' do
      result = task.process_references(
        build_tree(
          'nested' => { 'reference' => { 'a' => nil, 'b' => { 'c' => nil } } },
          'not-a-reference' => nil
        ),
        build_tree(
          'nested' => { 'reference' => :'resolved.nested' }
        )
      )
      expect(result.map(&:to_hash)).to(
        eq [{ 'nested' => { 'reference' => { 'a' => nil, 'b' => { 'c' => nil } } } },
            { 'resolved' => { 'nested' => { 'a' => nil, 'b' => { 'c' => nil } } } },
            { 'nested' => { 'reference' => nil } }]
      )
    end

    it 'returns empty array when nothing to resolve' do
      result = task.process_references(
        build_tree('not-a-reference' => nil),
        build_tree('reference' => :resolved)
      )
      expect(result.map(&:to_hash)).to(eq [{}, {}, {}])
    end
  end
end
