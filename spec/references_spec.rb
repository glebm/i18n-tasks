# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Reference keys' do
  let(:task) { ::I18n::Tasks::BaseTask.new }

  describe '#resolve_references' do
    it 'resolves plain references' do
      result = task.resolve_references(
          build_tree('en' => {
              'reference'       => nil,
              'not-a-reference' => nil
          }),
          build_tree('en' => {
              'reference' => :resolved
          }))
      expect(result).to(eq %w(reference resolved))
    end

    it 'resolves nested references' do
      result = task.resolve_references(
          build_tree('en' => {
              'reference'       => {'a' => nil, 'b' => {'c' => nil}},
              'not-a-reference' => nil
          }),
          build_tree('en' => {
              'reference' => :resolved
          }))
      expect(result).to(eq %w(reference resolved.a resolved.b.c))
    end

    it 'resolves nested references with nested keys' do
      result = task.resolve_references(
          build_tree('en' => {
              'nested'          => {'reference' => {'a' => nil, 'b' => {'c' => nil}}},
              'not-a-reference' => nil
          }),
          build_tree('en' => {
              'nested' => {'reference' => :resolved}
          }))
      expect(result).to(eq %w(nested.reference resolved.a resolved.b.c))
    end

    it 'returns empty array when nothing to resolve' do
      result = task.resolve_references(
          build_tree('en' => {
                         'not-a-reference' => nil
                     }),
          build_tree('en' => {
                         'reference' => :resolved
                     }))
      expect(result).to(eq [])
    end
  end
end
