# frozen_string_literal: true

require "spec_helper"

RSpec.describe "UsedKeysCustomScanner" do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:paths) do
    %w[custom_scanner.what_rb]
  end

  around do |ex|
    I18n::Tasks.add_scanner(
      "::I18n::Tasks::Scanners::RubyScanner",
      receiver_messages: [nil, AST::Node.new(:const, [nil, :It])].product(%i[it]),
      only: %w[*.what_rb]
    )
    task.config[:search] = {paths: paths}
    TestCodebase.in_test_app_dir(directory: "spec/fixtures/used_keys") { ex.run }
  end

  it "#used_keys" do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = used_keys.leaves.to_a
    expect(leaves.size).to(eq(2))

    expect_node_key_data(
      leaves[0],
      "matches_custom_scanner",
      occurrences: make_occurrences(
        [
          {
            path: "custom_scanner.what_rb",
            pos: 0,
            line_num: 1,
            line_pos: 0,
            line: 'it("matches_custom_scanner")',
            raw_key: "matches_custom_scanner"
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[1],
      "matches_custom_scanner_on_It",
      occurrences: make_occurrences(
        [
          {
            path: "custom_scanner.what_rb",
            pos: 29,
            line_num: 2,
            line_pos: 0,
            line: 'It.it("matches_custom_scanner_on_It")',
            raw_key: "matches_custom_scanner_on_It"
          }
        ]
      )
    )
  end
end
