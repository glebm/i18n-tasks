require 'spec_helper'

describe 'UsedKeys' do
  let(:task) { I18n::Tasks::BaseTask.new }

  it 'shows usages' do
    task.config[:search] = {paths: ['a.html.slim']}
    TestCodebase.setup('a.html.slim' => <<-SLIM)
div = t 'a'
  p = t 'a'
    SLIM
    TestCodebase.in_test_app_dir {
      used_keys = task.used_keys
      expect(used_keys.size).to eq 1
      usages_expected = [
          {pos: 6, line_num: 1, line_pos: 7, line: "div = t 'a'", path: 'a.html.slim'},
          {pos: 18, line_num: 2, line_pos: 7, line: "  p = t 'a'", path: 'a.html.slim'}
      ]
      expect(used_keys[0].attr).to eq(type: :used, key: 'a', usages: usages_expected)
    }
  end
end
