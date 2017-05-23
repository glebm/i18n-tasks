# frozen_string_literal: true
require 'spec_helper'
require 'i18n/tasks/scanners/model_scanner'

RSpec.describe 'ModelScanner' do
  describe '#scan_file' do
    let(:expected_key) do
      'activerecord.attributes.event.type'
    end

    let(:expected_occurrence) do
      { path:     'spec/fixtures/app/models/event.rb',
        pos:      149,
        line_num: 8,
        line_pos: 24,
        line:     "#  seclevel   :integer\n#  type       :string",
        raw_key:  'type' }
    end

    it 'finds absolute keys from model annotation' do
      file_path = expected_occurrence[:path]
      scanner   = I18n::Tasks::Scanners::ModelScanner.new(
        config: { paths: ['spec/fixtures/'], only: [file_path] }
      )

      expect(scanner.keys.detect { |key_occurrences| key_occurrences.key =~ /type/ }).to(
        eq make_key_occurrences(expected_key, [expected_occurrence])
      )
    end
  end
end
