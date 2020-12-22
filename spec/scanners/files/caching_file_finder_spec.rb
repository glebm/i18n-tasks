# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/files/caching_file_finder'

RSpec.describe 'CachingFileFinder' do
  let(:test_files) do
    %w[a/a/a/a.txt a/a/a.txt a/a/b.txt a/b/a.txt a/b/b.txt a.txt]
  end
  describe '#find_files' do
    it 'accesses the filesystem only once' do
      TestCodebase.setup(test_files.each_with_object({}) { |f, h| h[f] = '' })
      TestCodebase.in_test_app_dir do
        finder = I18n::Tasks::Scanners::Files::CachingFileFinder.new
        expect(finder.find_files).to eq(test_files.map { |f| File.join('.', f) })
        TestCodebase.teardown
        expect(finder.find_files).to eq(test_files.map { |f| File.join('.', f) })
      end
    ensure
      TestCodebase.teardown
    end
  end

  describe '#traverse_files' do
    it 'accesses the filesystem only once' do
      TestCodebase.setup(test_files.each_with_object({}) { |f, h| h[f] = '' })
      TestCodebase.in_test_app_dir do
        finder = I18n::Tasks::Scanners::Files::CachingFileFinder.new
        expect(finder.traverse_files { |f| f }).to eq(test_files.map { |f| File.join('.', f) })
        TestCodebase.teardown
        expect(finder.traverse_files { |f| f }).to eq(test_files.map { |f| File.join('.', f) })
      end
    ensure
      TestCodebase.teardown
    end
  end
end
