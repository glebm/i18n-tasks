# frozen_string_literal: true

require "spec_helper"

RSpec.describe "UsedKeysHaml" do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:file_name) { "a.html.haml" }
  let(:file_content) do
    <<~HAML
      #first{ title: t('a') }
      .second{ title: t('a') }
      - # t('a') in a comment is ignored
    HAML
  end

  around do |ex|
    task.config[:search] = {paths: [file_name]}
    TestCodebase.setup(file_name => file_content)
    TestCodebase.in_test_app_dir { ex.run }
    TestCodebase.teardown
  end

  it "#used_keys(source_occurences: true)" do
    used_keys = task.used_tree
    expect(used_keys.size).to eq 1
    expect_node_key_data(
      used_keys.leaves.first,
      "a",
      occurrences: make_occurrences(
        [{path: "a.html.haml", pos: 15, line_num: 1, line_pos: 16,
          line: "#first{ title: t('a') }", raw_key: "a"},
          {path: "a.html.haml", pos: 40, line_num: 2, line_pos: 17,
           line: ".second{ title: t('a') }", raw_key: "a"}]
      )
    )
  end
end
