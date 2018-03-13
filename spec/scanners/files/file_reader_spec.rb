# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/files/file_reader'

RSpec.describe 'FileReader' do
  describe '#read_file' do
    around do |ex|
      TestCodebase.setup('test.txt' => 'test')
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end
    it 'reads the file' do
      expect(I18n::Tasks::Scanners::Files::FileReader.new.read_file('test.txt')).to eq('test')
    end
  end
end
