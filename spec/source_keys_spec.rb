require 'spec_helper'

describe 'Source keys' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  describe 'pattern' do
    let!(:pattern) { task.search_config[:pattern] }

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
