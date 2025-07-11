# frozen_string_literal: true

require "spec_helper"
# This spec is a duplicate of `spec/used_keys_erb_spec.rb` but what we expect for the Prism-based ERB-parser.
RSpec.describe "UsedKeysErbPrism" do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:paths) do
    %w[app/views/application/show.html.erb]
  end
  let!(:prism_visitor) { "rails" }

  around do |ex|
    task.config[:search] = {paths: paths, prism: prism_visitor}
    TestCodebase.in_test_app_dir(directory: "spec/fixtures/used_keys") { ex.run }
  end

  describe ".text.erb" do
    let(:paths) { %w[app/views/application/index.text.erb] }

    it "#used_keys" do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = leaves_to_hash(used_keys.leaves.to_a)

      expect(leaves.keys).to match_array(
        %w[
          text.a
          with_parameter
          scope_a.scope_b.with_scope
          application.index.nested_call
          application.index.edit
          blacklight.tools.citation
          comment.absolute.attribute
          activerecord.attributes.agenda_item.title
          activerecord.models.meeting_note.one
        ]
      )

      expected_occurrences(
        leaves,
        {
          "text.a" => [
            {path: "app/views/application/index.text.erb", line_num: 1},
            {path: "app/views/application/index.text.erb", line_num: 2}
          ],
          "with_parameter" => [
            {path: "app/views/application/index.text.erb", line_num: 11}
          ],
          "scope_a.scope_b.with_scope" => [
            {path: "app/views/application/index.text.erb", line_num: 12}
          ],
          "application.index.nested_call" => [
            {path: "app/views/application/index.text.erb", line_num: 12}
          ],
          "application.index.edit" => [
            {path: "app/views/application/index.text.erb", line_num: 15}
          ],
          "blacklight.tools.citation" => [
            {path: "app/views/application/index.text.erb", line_num: 21}
          ],
          "comment.absolute.attribute" => [
            {path: "app/views/application/index.text.erb", line_num: 5}
          ],
          "activerecord.attributes.agenda_item.title" => [
            {path: "app/views/application/index.text.erb", line_num: 8}
          ],
          "activerecord.models.meeting_note.one" => [
            {path: "app/views/application/index.text.erb", line_num: 7}
          ]
        }
      )
    end
  end

  describe ".html.erb" do
    let(:paths) { %w[app/views/application/show.html.erb] }

    it "#used_keys" do # rubocop:disable RSpec/ExampleLength
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = used_keys.leaves.to_a
      leaves_as_hash = leaves_to_hash(leaves)
      expect(leaves_as_hash.keys).to match_array(
        %w[
          a
          with_parameter
          scope_a.scope_b.with_scope
          application.show.nested_call
          application.show.edit
          blacklight.tools.citation
          comment.absolute.attribute
          activerecord.attributes.agenda_item.title
          activerecord.models.meeting_note.one
        ]
      )

      expect_node_key_data(
        leaves[0],
        "a",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 18,
                line_num: 1,
                line_pos: 18,
                line: "<div id=first><%= t('a') %></div>",
                raw_key: "a"
              },
              {
                path: "app/views/application/show.html.erb",
                pos: 44,
                line_num: 2,
                line_pos: 10,
                line: "<% what = t 'a' %>",
                raw_key: "a"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[2],
        "activerecord.models.meeting_note.one",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 185,
                line_num: 7,
                line_pos: 6,
                line: "  <%= MeetingNote.model_name.human(count: 1) %>",
                raw_key: "activerecord.models.meeting_note.one"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[3],
        "activerecord.attributes.agenda_item.title",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 233,
                line_num: 8,
                line_pos: 6,
                line: "  <%= AgendaItem.human_attribute_name(:title) %>",
                raw_key: "activerecord.attributes.agenda_item.title"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[4],
        "with_parameter",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 293,
                line_num: 11,
                line_pos: 6,
                line:
                  "  <%= t('with_parameter', parameter: \"erb is the best\") %>",
                raw_key: "with_parameter"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[5],
        "scope_a.scope_b.with_scope",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 352,
                line_num: 12,
                line_pos: 6,
                line:
                  "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
                raw_key: "with_scope"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[6],
        "application.show.nested_call",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 403,
                line_num: 12,
                line_pos: 57,
                line:
                  "  <%= t 'with_scope', scope: \"scope_a.scope_b\", default: t(\".nested_call\") %>",
                raw_key: ".nested_call"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[7],
        "application.show.edit",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 523,
                line_num: 15,
                line_pos: 41,
                line:
                  '  <%= link_to(edit_foo_path(foo), title: t(".edit")) do %>',
                raw_key: ".edit"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[8],
        "blacklight.tools.citation",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 745,
                line_num: 21,
                line_pos: 25,
                line:
                  "    <% component.title { t('blacklight.tools.citation') } %>",
                raw_key: "blacklight.tools.citation"
              }
            ]
          )
      )

      expect_node_key_data(
        leaves[1],
        "comment.absolute.attribute",
        occurrences:
          make_occurrences(
            [
              {
                path: "app/views/application/show.html.erb",
                pos: 88,
                line_num: 5,
                line_pos: 5,
                line: "  <% # i18n-tasks-use t('comment.absolute.attribute') %>",
                raw_key: "comment.absolute.attribute"
              }
            ]
          )
      )
    end

    describe "without rails_model matcher" do
      let(:prism_visitor) { "ruby" }

      it "#used_keys" do
        used_keys = task.used_tree
        expect(used_keys.size).to eq(1)
        leaves = leaves_to_hash(used_keys.leaves.to_a)

        expect(leaves.keys).to match_array(
          %w[
            a
            with_parameter
            scope_a.scope_b.with_scope
            blacklight.tools.citation
            comment.absolute.attribute
          ]
        )
      end
    end

    describe "comments" do
      let(:paths) { %w[app/views/application/comments.html.erb] }

      it "#used_keys" do
        used_keys = task.used_tree
        expect(used_keys.size).to eq(1)
        leaves = used_keys.leaves.to_a
        expect(leaves.size).to eq(8)

        expect_node_key_data(
          leaves[0],
          "ruby.comment.works",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 90,
                  line_num: 4,
                  line_pos: 3,
                  line: "<% # i18n-tasks-use t('ruby.comment.works') %>",
                  raw_key: "ruby.comment.works"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[1],
          "erb.comment.works",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 194,
                  line_num: 7,
                  line_pos: 23,
                  line: "<%# i18n-tasks-use t('erb.comment.works') %>",
                  raw_key: "erb.comment.works"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[2],
          "erb_multi.comment.line1",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 275,
                  line_num: 10,
                  line_pos: 23,
                  line: "<%# i18n-tasks-use t('erb_multi.comment.line1')",
                  raw_key: "erb_multi.comment.line1"
                }
              ]
            )
        )

        # Will match the same row as leaves[2] for now
        expect_node_key_data(
          leaves[3],
          "erb_multi.comment.line2",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 319,
                  line_num: 11,
                  line_pos: 19,
                  line: "i18n-tasks-use t('erb_multi.comment.line2') %>",
                  raw_key: "erb_multi.comment.line2"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[4],
          "erb_multi_dash.comment.line1",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 409,
                  line_num: 15,
                  line_pos: 18,
                  line: "i18n-tasks-use t('erb_multi_dash.comment.line1')",
                  raw_key: "erb_multi_dash.comment.line1"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[5],
          "erb_multi_dash.comment.line2",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 458,
                  line_num: 16,
                  line_pos: 18,
                  line: "i18n-tasks-use t('erb_multi_dash.comment.line2') -%>",
                  raw_key: "erb_multi_dash.comment.line2"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[6],
          "ruby_multi.comment.line1",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 540,
                  line_num: 20,
                  line_pos: 3,
                  line: "<%\n# i18n-tasks-use t('ruby_multi.comment.line1')",
                  raw_key: "ruby_multi.comment.line1"
                }
              ]
            )
        )

        expect_node_key_data(
          leaves[7],
          "ruby_multi.comment.line2",
          occurrences:
            make_occurrences(
              [
                {
                  path: "app/views/application/comments.html.erb",
                  pos: 540,
                  line_num: 20,
                  line_pos: 3,
                  line: "<%\n# i18n-tasks-use t('ruby_multi.comment.line1')",
                  raw_key: "ruby_multi.comment.line2"
                }
              ]
            )
        )
      end
    end
  end
end
