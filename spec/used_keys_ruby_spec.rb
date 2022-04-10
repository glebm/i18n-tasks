# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/ast_matchers/rails_model_matcher'

RSpec.describe 'UsedKeysRuby' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  around do |ex|
    I18n::Tasks::Configuration::DEFAULTS[:search][:ast_matchers].clear
    ast_matchers.each do |matcher|
      I18n::Tasks.add_ast_matcher(matcher)
    end
    task.config[:search] = { paths: paths, strict: strict }
    TestCodebase.in_test_app_dir(directory: 'spec/fixtures/used_keys') { ex.run }
  end

  let(:paths) do
    %w[a.rb]
  end

  let(:strict) do
    true
  end

  let(:ast_matchers) do
    %w[I18n::Tasks::Scanners::AstMatchers::RailsModelMatcher]
  end

  it '#used_keys - ruby' do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = used_keys.leaves.to_a
    expect(leaves.size).to(eq(5))

    expect_node_key_data(
      leaves[0],
      'a',
      occurrences: make_occurrences(
        [
          { path: 'a.rb', pos: 23, line_num: 3, line_pos: 4, line: "    t('a')", raw_key: 'a' },
          { path: 'a.rb', pos: 52, line_num: 7, line_pos: 4, line: "    I18n.t('a')", raw_key: 'a' }
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
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[2],
      'activerecord.attributes.archive.name',
      occurrences: make_occurrences(
        [
          {
            path: 'a.rb', pos: 276,
            line_num: 15, line_pos: 4,
            line: '    Archive.human_attribute_name(:name)',
            raw_key: 'activerecord.attributes.archive.name'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[3],
      'activerecord.models.user',
      occurrences: make_occurrences(
        [
          {
            path: 'a.rb', pos: 316,
            line_num: 16, line_pos: 4,
            line: '    User.model_name.human(count: 2)',
            raw_key: 'activerecord.models.user'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[4],
      'service.what',
      occurrences: make_occurrences(
        [
          {
            path: 'a.rb',
            pos: 130,
            line_num: 12,
            line_pos: 4,
            line: '    Service.translate(:what)',
            raw_key: 'service.what'
          }
        ]
      )
    )
  end

  describe 'strict = false' do
    let(:strict) { false }

    it '#used_keys' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      expect(leaves.size).to(eq(6))
    end
  end

  describe 'without rails_model matcher' do
    let(:ast_matchers) { [] }

    it '#used_keys' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      expect(leaves.size).to(eq(3))
    end
  end
end
