# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PatternWithScopeScanner' do
  def stub_source(scanner, source)
    allow(scanner).to receive(:traverse_files) { |&block| [block.call('test')] }
    allow(scanner).to receive(:read_file) { source }
  end

  describe 'match_to_key' do
    let(:scanner) do
      I18n::Tasks::Scanners::PatternWithScopeScanner.new
    end

    it 'matches a literal scope' do
      stub_source scanner, '= t :key, scope: "scope"'
      expect(scanner.keys.map(&:key)).to eq(['scope.key'])

      stub_source scanner, '= t :key, scope: :scope'
      expect(scanner.keys.map(&:key)).to eq(['scope.key'])

      stub_source scanner, '= t :key, :scope => :scope'
      expect(scanner.keys.map(&:key)).to eq(['scope.key'])

      stub_source scanner, '= t :key, :scope => :scope, default: "Default"'
      expect(scanner.keys.map(&:key)).to eq(['scope.key'])
    end

    # rubocop:disable Lint/InterpolationCheck
    it 'matches a literal scope with a variable' do
      stub_source scanner, '= t key, scope: "scope"'
      expect(scanner.keys.map(&:key)).to eq(['scope.#{key}'])
    end

    it 'matches a literal scope with an instance variable' do
      stub_source scanner, '= t @key, scope: "scope"'
      expect(scanner.keys.map(&:key)).to eq(['scope.#{@key}'])

      stub_source scanner, '= t @key.m, scope: "scope"'
      expect(scanner.keys.map(&:key)).to eq(['scope.#{@key.m}'])
    end
    # rubocop:enable Lint/InterpolationCheck

    it 'matches an array of literals scope' do
      stub_source scanner, '= t :key, :scope => [:a, :b]'
      expect(scanner.keys.map(&:key)).to eq(['a.b.key'])
    end

    it 'does not match anything else' do
      stub_source scanner, '= t :key, scope: a'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t :key, scope: []'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t :key, scope: [a]'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t :key, scope: [:x, [:y]]'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t :key, scope: (a)'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t key, scope: (a)'
      expect(scanner.keys.map(&:key)).to eq([])

      stub_source scanner, '= t key'
      expect(scanner.keys.map(&:key)).to eq([])
    end

    it 'matches only the scope argument' do
      stub_source scanner, '= t :key, :scope => [:a, :b] :c'
      expect(scanner.keys.map(&:key)).to eq(['a.b.key'])

      stub_source scanner, '= t :key, :scope => [:a, :b], :c'
      expect(scanner.keys.map(&:key)).to eq(['a.b.key'])
    end

    it 'matches nested calls' do
      stub_source scanner, '= t :key, scope: :a, name: t(:key, scope: :b)'
      expect(scanner.keys.map(&:key)).to eq(%w[a.key b.key])

      stub_source scanner, '= t :key, scope: [:a, :a], name: t(:key, scope: :b)'
      expect(scanner.keys.map(&:key)).to eq(%w[a.a.key b.key])
    end
  end
end
