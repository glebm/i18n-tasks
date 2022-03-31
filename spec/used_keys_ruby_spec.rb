# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UsedKeysRuby' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  around do |ex|
    task.config[:search] = { paths: paths }
    TestCodebase.in_test_app_dir(directory: 'spec/fixtures/used_keys') { ex.run }
  end

  let(:paths) {
    %w[a.rb]
  }

  it '#used_keys - ruby' do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = used_keys.leaves.to_a
    expect(leaves.size).to(eq(3))

    expect_node_key_data(
      leaves[0],
      'a',
      occurrences: make_occurrences(
        [
          {path: 'a.rb', pos: 23, line_num: 3, line_pos: 4, line: "    t('a')", raw_key: 'a' },
          {path: 'a.rb', pos: 52, line_num: 7, line_pos: 4, line: "    I18n.t('a')", raw_key: 'a' },
        ]
      )
    )

    expect_node_key_data(
      leaves[1],
      'activerecord.attributes.absolute.attribute',
      occurrences: make_occurrences(
        [
          {
            path: 'a.rb', pos: 159,
            line_num: 13, line_pos: 4,
            line: "    I18n.t('activerecord.attributes.absolute.attribute')",
            raw_key: 'activerecord.attributes.absolute.attribute'
          },
          {
            path: 'a.rb', pos: 216,
            line_num: 14, line_pos: 4,
            line: "    translate('activerecord.attributes.absolute.attribute')",
            raw_key: 'activerecord.attributes.absolute.attribute'
          },
        ]
      )
    )

    expect_node_key_data(
      leaves[2],
      'service.what',
      occurrences: make_occurrences(
        [
          {
            path: 'a.rb',
            pos: 130,
            line_num: 12,
            line_pos: 4,
            line: "    Service.translate(:what)",
            raw_key: 'service.what'
          }
        ]
      )
    )
  end
end
