require 'spec_helper'

describe 'Pattern Scanner' do
  describe 'default pattern' do
    let!(:pattern) { I18n::Tasks::Scanners::PatternScanner::DEFAULT_PATTERN }

    ['t "a.b"', "t 'a.b'", 't("a.b")', "t('a.b')",
     "t('a.b', :arg => val)", "t('a.b', arg: val)",
     "t :a_b", "t :'a.b'", 't :"a.b"', "t(:ab)", "t(:'a.b')", 't(:"a.b")',
    'I18n.t("a.b")', 'I18n.translate("a.b")'].each do |s|
      it "matches #{s}" do
        pattern.should match s
      end
    end

    ["t \"a.b'", "t a.b"].each do |s|
      it "does not match #{s}" do
        pattern.should_not match s
      end
    end
  end
end
