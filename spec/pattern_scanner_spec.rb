# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PatternScanner' do
  describe '#keys' do
    let(:expected_key) do
      'events.show.success'
    end

    let(:expected_occurrence) do
      { path: 'spec/fixtures/app/controllers/events_controller.rb',
        pos: 836,
        line_num: 32,
        line_pos: 5,
        line: '    t(".success")',
        raw_key: '.success' }
    end

    it 'returns absolute keys from controllers' do
      file_path = 'spec/fixtures/app/controllers/events_controller.rb'
      scanner   = I18n::Tasks::Scanners::PatternScanner.new(
        config: { paths: ['spec/fixtures/'], only: [file_path], relative_roots: ['spec/fixtures/app/controllers'] }
      )
      allow(scanner).to receive(:relative_roots).and_return(['spec/fixtures/app/controllers'])
      expect(scanner.keys.detect { |key_occurrences| key_occurrences.key =~ /success/ }).to(
        eq make_key_occurrences(expected_key, [expected_occurrence])
      )
    end
  end

  describe 'default_pattern' do
    let!(:pattern) { I18n::Tasks::Scanners::PatternScanner.new.send(:default_pattern) }

    ['t(".a.b")',
     't "a.b"',
     "t 'a.b'",
     't("a.b")',
     "t('a.b')",
     "t('a.b', :arg => val)",
     "t('a.b', arg: val)",
     't :a_b',
     "t :'a.b'",
     't :"a.b"',
     't(:ab)',
     "t(:'a.b')",
     't(:"a.b")',
     'I18n.t("a.b")',
     'I18n.translate("a.b")'].each do |string|
      it "matches #{string}" do
        expect(pattern).to match string
      end
    end

    ["t \"a.b'", 't a.b'].each do |string|
      it "does not match #{string}" do
        expect(pattern).to_not match string
      end
    end
  end
end
