# frozen_string_literal: true
require 'spec_helper'
require 'i18n/tasks/scanners/scanner_multiplexer'

RSpec.describe 'ScannerMultiplexer' do
  describe '#keys' do
    let(:key_a) { make_key_occurrences 'key.a', [{path: 'a'}] }
    let(:key_b_1) { make_key_occurrences 'key.b', [{path: 'b1'}] }
    let(:key_b_2) { make_key_occurrences 'key.b', [{path: 'b2'}] }
    let(:key_c) { make_key_occurrences 'key.c', [{path: 'c'}] }

    scanner_mock = Struct.new(:keys)
    let(:scanner_one) { scanner_mock.new([key_a, key_b_1]) }
    let(:scanner_two) { scanner_mock.new([key_b_2, key_c]) }

    let(:expected_key_occurrences) {
      [key_a,
       I18n::Tasks::Scanners::Results::KeyOccurrences.new(
           key: 'key.b', occurrences: key_b_1.occurrences + key_b_2.occurrences),
       key_c]
    }

    it 'returns the merged results' do
      scanner_multiplexer = I18n::Tasks::Scanners::ScannerMultiplexer.new(scanners: [scanner_one, scanner_two])
      expect(scanner_multiplexer.keys).to eq expected_key_occurrences
    end
  end
end
