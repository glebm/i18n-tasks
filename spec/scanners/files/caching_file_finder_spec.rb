require 'spec_helper'
require 'i18n/tasks/scanners/files/caching_file_finder'

RSpec.describe 'CachingFileFinder' do
  let(:test_files) {
    %w(a/a/a/a.txt a/a/a.txt a/a/b.txt a/b/a.txt a/b/b.txt a.txt)
  }
  describe '#find_files' do
    it 'accesses the filesystem only once' do
      begin
        TestCodebase.setup(test_files.inject({}) { |h, f| h[f] = ''; h })
        TestCodebase.in_test_app_dir {
          finder = I18n::Tasks::Scanners::Files::CachingFileFinder.new
          expect(finder.find_files).to eq test_files.map { |f| File.join('.', f) }
          TestCodebase.teardown
          expect(finder.find_files).to eq test_files.map { |f| File.join('.', f) }
        }
      ensure
        TestCodebase.teardown
      end
    end
  end

  describe '#traverse_files' do
    it 'accesses the filesystem only once' do
      begin
        TestCodebase.setup(test_files.inject({}) { |h, f| h[f] = ''; h })
        TestCodebase.in_test_app_dir {
          finder = I18n::Tasks::Scanners::Files::CachingFileFinder.new
          expect(finder.traverse_files { |f| f }).to eq test_files.map { |f| File.join('.', f) }
          TestCodebase.teardown
          expect(finder.traverse_files { |f| f }).to eq test_files.map { |f| File.join('.', f) }
        }
      ensure
        TestCodebase.teardown
      end
    end
  end
end
