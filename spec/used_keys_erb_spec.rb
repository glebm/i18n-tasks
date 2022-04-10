# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/ast_matchers/rails_model_matcher'

RSpec.describe 'UsedKeysErb' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  around do |ex|
    I18n::Tasks::Configuration::DEFAULTS[:search][:ast_matchers].clear
    ast_matchers.each do |matcher|
      I18n::Tasks.add_ast_matcher(matcher)
    end
    task.config[:search] = { paths: paths }
    TestCodebase.in_test_app_dir(directory: 'spec/fixtures/used_keys') { ex.run }
  end

  let(:paths) do
    %w[app/views/application/show.html.erb]
  end

  let(:ast_matchers) do
    %w[I18n::Tasks::Scanners::AstMatchers::RailsModelMatcher]
  end

  it '#used_keys' do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = used_keys.leaves.to_a
    expect(leaves.size).to eq(9)

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
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[1],
      'activerecord.models.meeting_note',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 184,
            line_num: 7, line_pos: 5,
            line: '  <%= MeetingNote.model_name.human(count: 1) %>',
            raw_key: 'activerecord.models.meeting_note'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[2],
      'activerecord.attributes.agenda_item.title',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 232,
            line_num: 8, line_pos: 5,
            line: '  <%= AgendaItem.human_attribute_name(:title) %>',
            raw_key: 'activerecord.attributes.agenda_item.title'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[3],
      'with_parameter',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 292,
            line_num: 11, line_pos: 5,
            line: "  <%= t('with_parameter', parameter: \"erb is the best\") %>",
            raw_key: 'with_parameter'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[4],
      'scope_a.scope_b.with_scope',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 351,
            line_num: 12, line_pos: 5,
            line: "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
            raw_key: 'scope_a.scope_b.with_scope'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[5],
      'application.show.nested_call',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 403,
            line_num: 12, line_pos: 57,
            line: "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
            raw_key: '.nested_call'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[6],
      'application.show.edit',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 523,
            line_num: 15, line_pos: 41,
            line: '  <%= link_to(edit_foo_path(foo), title: t(".edit")) do %>',
            raw_key: '.edit'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[7],
      'blacklight.tools.citation',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 745,
            line_num: 21, line_pos: 25,
            line: "    <% component.title { t('blacklight.tools.citation') } %>",
            raw_key: 'blacklight.tools.citation'
          }
        ]
      )
    )

    expect_node_key_data(
      leaves[8],
      'comment.absolute.attribute',
      occurrences: make_occurrences(
        [
          {
            path: 'app/views/application/show.html.erb',
            pos: 88,
            line_num: 5, line_pos: 4,
            line: "  <% # i18n-tasks-use t('comment.absolute.attribute') %>",
            raw_key: 'comment.absolute.attribute'
          }
        ]
      )
    )
  end

  describe 'comments' do
    let(:paths) do
      %w[app/views/application/comments.html.erb]
    end

    it '#used_keys' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      expect(leaves.size).to eq(8)

      expect_node_key_data(
        leaves[0],
        'ruby.comment.works',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 90,
              line_num: 4, line_pos: 2,
              line: "<% # i18n-tasks-use t('ruby.comment.works') %>",
              raw_key: 'ruby.comment.works'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[1],
        'erb.comment.works',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 174,
              line_num: 7, line_pos: 4,
              line: "<%# i18n-tasks-use t('erb.comment.works') %>",
              raw_key: 'erb.comment.works'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[2],
        'erb_multi.comment.line1',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 255,
              line_num: 10, line_pos: 2,
              line: "<%# i18n-tasks-use t('erb_multi.comment.line1')",
              raw_key: 'erb_multi.comment.line1'
            }
          ]
        )
      )

      # Will match the same row as leaves[2] for now
      expect_node_key_data(
        leaves[3],
        'erb_multi.comment.line2',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 255,
              line_num: 10, line_pos: 2,
              line: "<%# i18n-tasks-use t('erb_multi.comment.line1')",
              raw_key: 'erb_multi.comment.line2'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[4],
        'erb_multi_dash.comment.line1',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 389,
              line_num: 14, line_pos: 2,
              line: '<%#-',
              raw_key: 'erb_multi_dash.comment.line1'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[5],
        'erb_multi_dash.comment.line2',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 389,
              line_num: 14, line_pos: 2,
              line: '<%#-',
              raw_key: 'erb_multi_dash.comment.line2'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[6],
        'ruby_multi.comment.line1',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 540,
              line_num: 19, line_pos: 2,
              line: '<%',
              raw_key: 'ruby_multi.comment.line1'
            }
          ]
        )
      )

      expect_node_key_data(
        leaves[7],
        'ruby_multi.comment.line2',
        occurrences: make_occurrences(
          [
            {
              path: 'app/views/application/comments.html.erb',
              pos: 588,
              line_num: 21, line_pos: 0,
              line: "# i18n-tasks-use t('ruby_multi.comment.line2') %>",
              raw_key: 'ruby_multi.comment.line2'
            }
          ]
        )
      )
    end
  end

  describe 'without rails_model matcher' do
    let(:ast_matchers) { [] }

    it '#used_keys' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      expect(leaves.size).to(eq(7))
    end
  end
end
