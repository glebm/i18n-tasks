# coding: utf-8
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
    TestCodebase.teardown
  end

  it '#used_keys(src_locations: true)' do
    used_keys = task.used_keys(src_locations: true)
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

  it '#used_keys(src_locations: true, key_filter: "b*")' do
    used_keys = task.used_keys(key_filter: 'b*', src_locations: true)
    expect(used_keys.size).to eq 1
    expect(used_keys[0].own_attr).to(
        eq(key:    'b',
           usages: [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", path: 'a.html.slim'}])
    )
  end
end
