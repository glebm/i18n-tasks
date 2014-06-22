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

  it '#used_keys(source_locations: true)' do
    used   = task.used_tree(source_locations: true)
    leaves = used.leaves.to_a
    expect(leaves.size).to eq 2
    expect_node_key_data(
        leaves[0],
        'a',
        source_locations:
            [{pos: 6, line_num: 1, line_pos: 7, line: "div = t 'a'", src_path: 'a.html.slim'},
             {pos: 18, line_num: 2, line_pos: 7, line: "  p = t 'a'", src_path: 'a.html.slim'}]
    )

    expect_node_key_data(
        leaves[1],
        'b',
        source_locations:
            [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", src_path: 'a.html.slim'}]
    )
  end

  it '#used_keys(source_locations: true, key_filter: "b*")' do
    used_keys = task.used_tree(key_filter: 'b*', source_locations: true)
    expect(used_keys.size).to eq 1
    expect_node_key_data(
        used_keys.leaves.first,
        'b',
        source_locations:
            [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", src_path: 'a.html.slim'}]
    )
  end
end
