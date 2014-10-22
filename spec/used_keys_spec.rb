# coding: utf-8
require 'spec_helper'

describe 'UsedKeys' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:file_name) { 'a.html.slim' }
  let(:file_content) do
    <<-SLIM
div = t 'a'
  p = t 'a'
h1 = t 'b'
    SLIM
  end

  around do |ex|
    task.config[:search] = {paths: [file_name]}
    TestCodebase.setup(file_name => file_content)
    TestCodebase.in_test_app_dir { ex.run }
    TestCodebase.teardown
  end

  it '#used_keys(source_occurrences: true)' do
    used   = task.used_tree(source_occurrences: true)
    leaves = used.leaves.to_a
    expect(leaves.size).to eq 2
    expect_node_key_data(
        leaves[0],
        'a',
        source_occurrences:
            [{pos: 6, line_num: 1, line_pos: 7, line: "div = t 'a'", src_path: 'a.html.slim'},
             {pos: 18, line_num: 2, line_pos: 7, line: "  p = t 'a'", src_path: 'a.html.slim'}]
    )

    expect_node_key_data(
        leaves[1],
        'b',
        source_occurrences:
            [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", src_path: 'a.html.slim'}]
    )
  end

  it '#used_keys(source_occurrences: true, key_filter: "b*")' do
    used_keys = task.used_tree(key_filter: 'b*', source_occurrences: true)
    expect(used_keys.size).to eq 1
    expect_node_key_data(
        used_keys.leaves.first,
        'b',
        source_occurrences:
            [{pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", src_path: 'a.html.slim'}]
    )
  end

  describe 'when input is haml' do
    let(:file_name) { 'a.html.haml' }
    let(:file_content) do
      <<-HAML
#first{ title: t('a') }
.second{ title: t('a') }
- # t('a') in a comment is ignored
      HAML
    end

    it '#used_keys(source_occurences: true)' do
      used_keys = task.used_tree(source_occurrences: true)
      expect(used_keys.size).to eq 1
      expect_node_key_data(
          used_keys.leaves.first,
          'a',
          source_occurrences:
              [{pos: 15, line_num: 1, line_pos: 16, line: "#first{ title: t('a') }", src_path: 'a.html.haml'},
               {pos: 40, line_num: 2, line_pos: 17, line: ".second{ title: t('a') }", src_path: 'a.html.haml'}]
      )
    end
  end
end
