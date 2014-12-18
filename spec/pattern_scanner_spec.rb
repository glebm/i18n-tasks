# coding: utf-8
require 'spec_helper'

describe 'Pattern Scanner' do
  describe 'scan_file' do
    it 'returns absolute keys from controllers' do
      file_path = 'spec/fixtures/app/controllers/events_controller.rb'
      scanner = I18n::Tasks::Scanners::PatternScanner.new
      allow(scanner).to receive(:relative_roots).and_return(['spec/fixtures/app/controllers'])

      keys = scanner.scan_file(file_path)

      expect(keys).to include(
        ["events.show.success",
         {:data=>
          {
            :src_path=>"spec/fixtures/app/controllers/events_controller.rb",
            :pos=>790,
            :line_num=>34,
            :line_pos=>10,
            :line =>"    I18n.t(\".success\")"}
           }
         ]
      )
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
