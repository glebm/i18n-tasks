# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UsedKeysErb' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  around do |ex|
    task.config[:search] = { paths: paths }
    TestCodebase.in_test_app_dir(directory: 'spec/fixtures/used_keys') { ex.run }
  end

  let(:paths) {
    %w[app/views/application/show.html.erb]
  }

  it '#used_keys' do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = used_keys.leaves.to_a
    expect(leaves.size).to eq(7)

    expect_node_key_data(
      leaves[0],
      'a',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 17,
            line_num: 1, line_pos: 17,
            line: "<div id=first><%= t('a') %></div>",
            raw_key: 'a'
          },
          {
            path: 'app/views/application/show.html.erb',
            pos: 44,
            line_num: 2, line_pos: 10,
            line: "<% what = t 'a' %>",
            raw_key: 'a'
          },
        ]
      )
    )
    expect_node_key_data(
      leaves[1],
      'with_parameter',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 318,
            line_num: 11, line_pos: 5,
            line: "  <%= t('with_parameter', parameter: \"erb is the best\") %>",
            raw_key: 'with_parameter'
          }
        ]
      )
    )
    expect_node_key_data(
      leaves[2],
      'scope_a.scope_b.with_scope',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 377,
            line_num: 12, line_pos: 5,
            line: "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
            raw_key: 'scope_a.scope_b.with_scope'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[3],
      'application.show.nested_call',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 429,
            line_num: 12, line_pos: 57,
            line: "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
            raw_key: '.nested_call'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[4],
      "application.show.edit",
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 548,
            line_num: 14, line_pos: 41,
            line: '  <%= link_to(edit_foo_path(foo), title: t(".edit")) do %>',
            raw_key: '.edit'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[5],
      "blacklight.tools.citation",
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 770,
            line_num: 20, line_pos: 25,
            line: "    <% component.title { t('blacklight.tools.citation') } %>",
            raw_key: 'blacklight.tools.citation'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[6],
      'activerecord.models.first.one',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 88,
            line_num: 5, line_pos: 4,
            line: "  <% # i18n-tasks-use t('activerecord.models.first.one') %>",
            raw_key: 'activerecord.models.first.one'
          }
        ]
      )
    )
  end

  describe "test" do
    let(:paths) {
      %w[app/views/application/what.html.erb]
    }

    it "whatt" do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      expect(leaves.size).to eq(7)
    end
  end

  describe "what" do
    let(:paths) {
      %w[app/views/application/magic_comments.html.erb]
    }

    it "whatt" do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      binding.irb
      expect(leaves.size).to eq(7)
    end
  end
end
