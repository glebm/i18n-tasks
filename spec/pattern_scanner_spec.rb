require 'spec_helper'

RSpec.describe 'Pattern Scanner' do
  describe 'scan_file' do
    let(:expected_key) {
      'events.show.success'
    }

    let(:expected_data) {
      {src_path: 'spec/fixtures/app/controllers/events_controller.rb',
       pos:      774,
       line_num: 33,
       line_pos: 10,
       line:     '    I18n.t(".success")'}
    }

    it 'returns absolute keys from controllers' do
      file_path = 'spec/fixtures/app/controllers/events_controller.rb'
      scanner   = I18n::Tasks::Scanners::PatternScanner.new
      allow(scanner).to receive(:relative_roots).and_return(['spec/fixtures/app/controllers'])
      found_key = scanner.scan_file(file_path).detect { |key| key[0] == expected_key }
      expect(found_key).to_not be_nil
      expect(found_key).to eq [expected_key, data: expected_data]
    end
  end

  describe 'default_pattern' do
    let!(:pattern) { I18n::Tasks::Scanners::PatternScanner.new.default_pattern }

    [
      't(".a.b")',
      't "a.b"',
      "t 'a.b'",
      't("a.b")',
      "t('a.b')",
      "t('a.b', :arg => val)",
      "t('a.b', arg: val)",
      "t :a_b",
      "t :'a.b'",
      't :"a.b"',
      "t(:ab)",
      "t(:'a.b')",
      't(:"a.b")',
      'I18n.t("a.b")',
      'I18n.translate("a.b")'
    ].each do |string|
      it "matches #{string}" do
        expect(pattern).to match string
      end
    end

    ["t \"a.b'", "t a.b"].each do |string|
      it "does not match #{string}" do
        expect(pattern).to_not match string
      end
    end
  end
end
