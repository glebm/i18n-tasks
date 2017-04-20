# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/files/file_finder'

RSpec.describe 'FileFinder' do
  let(:test_files) do
    %w[a/a/a/a.txt a/a/a.txt a/a/b.txt a/b/a.txt a/b/b.txt a.txt]
  end
  around do |ex|
    TestCodebase.setup(test_files.each_with_object({}) { |f, h| h[f] = '' })
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe '#find_files' do
    it 'finds all the files in the current directory with default options' do
      finder = I18n::Tasks::Scanners::Files::FileFinder.new
      expect(finder.find_files).to eq(test_files.map { |f| File.join('.', f) })
    end

    it 'finds only the files in paths' do
      finder = I18n::Tasks::Scanners::Files::FileFinder.new(paths: %w[a/a a/b/a.txt])
      expect(finder.find_files).to eq(test_files.select { |f| f.start_with?('a/a/') || f == 'a/b/a.txt' })
    end

    it 'find only the files specified by the inclusion patterns' do
      finder = I18n::Tasks::Scanners::Files::FileFinder.new(
        paths: %w[a], only: %w[a/a/**]
      )
      expect(finder.find_files).to eq(test_files.select { |f| f.start_with?('a/a/') })
    end

    it 'finds only the files not specified by the exclusion patterns' do
      finder = I18n::Tasks::Scanners::Files::FileFinder.new(
        exclude: %w[./a/a/**]
      )
      expect(finder.find_files).to(
        eq(test_files.reject { |f| f.start_with?('a/a/') }.map { |f| File.join('.', f) })
      )
    end
  end

  describe '#traverse_files' do
    let(:finder) { I18n::Tasks::Scanners::Files::FileFinder.new }

    it 'yields all the files' do
      actual = []
      finder.traverse_files { |f| actual << f }
      expect(actual).to eq(test_files.map { |f| File.join('.', f) })
    end

    it 'returns the results from the block' do
      i = 0
      expect(finder.traverse_files { |_f| i += 1 }).to eq((1..test_files.length).to_a)
    end
  end
end
