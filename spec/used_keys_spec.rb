require 'spec_helper'

describe 'UsedKeys' do
  let!(:task) { I18n::Tasks::BaseTask.new }

  around do |ex|
    task.config[:search] = {paths: ['a.html.slim']}
    TestCodebase.setup('a.html.slim' => <<-SLIM)
div = t 'a'
  p = t 'a'
h1 = t 'b'
    SLIM
    TestCodebase.in_test_app_dir { ex.run }
  end

  it '#used_keys(true) finds usages' do
    used_keys = task.used_keys(true)
    expect(used_keys.size).to eq 2
    expect(used_keys[0].own_attr).to(
        eq(key:    'a',
           usages: [{pos: 6, line_num: 1, line_pos: 7, line: "div = t 'a'", path: 'a.html.slim'},
                    {pos: 18, line_num: 2, line_pos: 7, line: "  p = t 'a'", path: 'a.html.slim'}])
    )
    expect(used_keys[1].own_attr).to(
        eq(key:    'b',
           usages: [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", path: 'a.html.slim'}])
    )
  end

  it '#used_keys(true) finds usages with filter' do
    used_keys = task.scanner.with_key_filter('b*') {
      task.used_keys(true)
    }
    expect(used_keys.size).to eq 1
    expect(used_keys[0].own_attr).to(
        eq(key:    'b',
           usages: [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", path: 'a.html.slim'}])
    )
  end
end
