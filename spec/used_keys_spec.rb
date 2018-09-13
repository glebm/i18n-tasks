# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UsedKeys' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:file_name) { 'a.html.slim' }
  let(:file_content) do
    <<~SLIM
      div = t 'a'
        p = t 'a'
      h1 = t 'b'
      h2 = t 'c.layer'
      h3 = t 'c.layer.underneath_c'
    SLIM
  end

  around do |ex|
    task.config[:search] = { paths: [file_name] }
    TestCodebase.setup(file_name => file_content)
    TestCodebase.in_test_app_dir { ex.run }
    TestCodebase.teardown
  end

  it '#used_keys' do
    allow(I18n::Tasks::Logging).to receive(:log_warn).exactly(0).times

    used   = task.used_tree
    leaves = used.leaves.to_a
    expect(leaves.size).to eq 3
    expect_node_key_data(
      leaves[0],
      'a',
      occurrences: make_occurrences(
        [{ path: 'a.html.slim', pos: 6, line_num: 1, line_pos: 7, line: "div = t 'a'", raw_key: 'a' },
         { path: 'a.html.slim', pos: 18, line_num: 2, line_pos: 7, line: "  p = t 'a'", raw_key: 'a' }]
      )
    )

    expect_node_key_data(
      leaves[1],
      'b',
      occurrences: make_occurrences(
        [{ path: 'a.html.slim', pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", raw_key: 'b' }]
      )
    )
  end

  it '#used_keys(key_filter: "b*")' do
    allow(I18n::Tasks::Logging).to receive(:log_warn).exactly(0).times

    used_keys = task.used_tree(key_filter: 'b*')
    expect(used_keys.size).to eq 1
    expect_node_key_data(
      used_keys.leaves.first,
      'b',
      occurrences: make_occurrences(
        [{ path: 'a.html.slim', pos: 29, line_num: 3, line_pos: 6, line: "h1 = t 'b'", raw_key: 'b' }]
      )
    )
  end

  describe 'when input is haml' do
    let(:file_name) { 'a.html.haml' }
    let(:file_content) do
      <<~HAML
        #first{ title: t('a') }
        .second{ title: t('a') }
        - # t('a') in a comment is ignored
      HAML
    end

    it '#used_keys(source_occurences: true)' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq 1
      expect_node_key_data(
        used_keys.leaves.first,
        'a',
        occurrences: make_occurrences(
          [{ path: 'a.html.haml', pos: 15, line_num: 1, line_pos: 16,
             line: "#first{ title: t('a') }", raw_key: 'a' },
           { path: 'a.html.haml', pos: 40, line_num: 2, line_pos: 17,
             line: ".second{ title: t('a') }", raw_key: 'a' }]
        )
      )
    end
  end
end
