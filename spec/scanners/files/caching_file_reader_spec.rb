# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/files/caching_file_reader'

RSpec.describe 'CachingFileReader' do
  describe '#read_file' do
    around do |ex|
      TestCodebase.setup('test.txt' => 'test')
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end
    it 'reads the file only once' do
      caching_file_reader = I18n::Tasks::Scanners::Files::CachingFileReader.new
      expect(caching_file_reader.read_file('test.txt')).to eq('test')
      File.write('test.txt', 'something else')
      expect(caching_file_reader.read_file('test.txt')).to eq('test')
    end
  end
end
