# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UsedKeysRuby' do
  let!(:task) { I18n::Tasks::BaseTask.new }
  let(:extra_search_config) { {} }
  let(:paths) { %w[a.rb] }
  let(:strict) { true }
  let(:ast_matchers) do
    %w[
      I18n::Tasks::Scanners::AstMatchers::RailsModelMatcher
      I18n::Tasks::Scanners::AstMatchers::DefaultI18nSubjectMatcher
    ]
  end

  around do |ex|
    I18n::Tasks::Configuration::DEFAULTS[:search][:ast_matchers].clear
    ast_matchers.each { |matcher| I18n::Tasks.add_ast_matcher(matcher) }
    task.config[:search] = { paths: paths, strict: strict }.merge(
      extra_search_config
    )
    TestCodebase.in_test_app_dir(directory: 'spec/fixtures/used_keys') do
      ex.run
    end
  end

  it '#used_keys - ruby' do
    used_keys = task.used_tree
    expect(used_keys.size).to eq(1)
    leaves = leaves_to_hash(used_keys.leaves.to_a)
    expect(leaves.size).to(eq(5))
    expect(leaves.keys.sort).to(
      match_array(
        %w[
          a
          activerecord.attributes.absolute.attribute
          activerecord.attributes.archive.name
          activerecord.models.user
          service.what
        ]
      )
    )

    expect_node_key_data(
      leaves['a'],
      'a',
      occurrences:
        make_occurrences(
          [
            {
              path: 'a.rb',
              pos: 23,
              line_num: 3,
              line_pos: 4,
              line: "    t('a')",
              raw_key: 'a'
            },
            {
              path: 'a.rb',
              pos: 52,
              line_num: 7,
              line_pos: 4,
              line: "    I18n.t('a')",
              raw_key: 'a'
            }
          ]
        )
    )

    expect_node_key_data(
      leaves['activerecord.attributes.absolute.attribute'],
      'activerecord.attributes.absolute.attribute',
      occurrences:
        make_occurrences(
          [
            {
              path: 'a.rb',
              pos: 159,
              line_num: 13,
              line_pos: 4,
              line: "    I18n.t('activerecord.attributes.absolute.attribute')",
              raw_key: 'activerecord.attributes.absolute.attribute'
            },
            {
              path: 'a.rb',
              pos: 216,
              line_num: 14,
              line_pos: 4,
              line:
                "    translate('activerecord.attributes.absolute.attribute')",
              raw_key: 'activerecord.attributes.absolute.attribute'
            }
          ]
        )
    )

    expect_node_key_data(
      leaves['activerecord.attributes.archive.name'],
      'activerecord.attributes.archive.name',
      occurrences:
        make_occurrences(
          [
            {
              path: 'a.rb',
              pos: 276,
              line_num: 15,
              line_pos: 4,
              line: '    Archive.human_attribute_name(:name)',
              raw_key: 'activerecord.attributes.archive.name'
            }
          ]
        )
    )

    expect_node_key_data(
      leaves['activerecord.models.user'],
      'activerecord.models.user',
      occurrences:
        make_occurrences(
          [
            {
              path: 'a.rb',
              pos: 316,
              line_num: 16,
              line_pos: 4,
              line: '    User.model_name.human(count: 2)',
              raw_key: 'activerecord.models.user'
            }
          ]
        )
    )

    expect_node_key_data(
      leaves['service.what'],
      'service.what',
      occurrences:
        make_occurrences(
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

  describe 'relative_roots' do
    let(:paths) do
      %w[
        app/components/event_component.rb
        app/controllers/events_controller.rb
        app/mailers/user_mailer.rb
      ]
    end
    let(:extra_search_config) do
      {
        relative_roots: %w[app/components app/controllers app/mailers],
        relative_exclude_method_name_paths: %w[app/components]
      }
    end

    it '#used_keys' do
      used_keys = task.used_tree
      expect(used_keys.size).to eq(1)
      leaves = leaves_to_hash(used_keys.leaves.to_a)
      expect(leaves.keys.sort).to(
        match_array(
          %w[
            absolute_key
            event_component.key
            events.create.relative_key
            events.method_a.from_before_action
            user_mailer.welcome_notification.subject
            very_absolute_key
          ]
        )
      )

      expect_node_key_data(
        leaves['event_component.key'],
        'event_component.key',
        occurrences:
          make_occurrences(
            [
              {
                path: 'app/components/event_component.rb',
                pos: 62,
                line_num: 3,
                line_pos: 4,
                line: '    t(".key")',
                raw_key: '.key'
              }
            ]
          )
      )

      expect_node_key_data(
        leaves['absolute_key'],
        'absolute_key',
        occurrences:
          make_occurrences(
            [
              {
                path: 'app/components/event_component.rb',
                pos: 76,
                line_num: 4,
                line_pos: 4,
                line: '    t("absolute_key")',
                raw_key: 'absolute_key'
              },
              {
                path: 'app/controllers/events_controller.rb',
                pos: 138,
                line_num: 6,
                line_pos: 4,
                line: '    t("absolute_key")',
                raw_key: 'absolute_key'
              }
            ]
          )
      )

      expect_node_key_data(
        leaves['events.create.relative_key'],
        'events.create.relative_key',
        occurrences:
          make_occurrences(
            [
              {
                path: 'app/controllers/events_controller.rb',
                pos: 115,
                line_num: 5,
                line_pos: 4,
                line: '    t(".relative_key")',
                raw_key: '.relative_key'
              }
            ]
          )
      )

      expect_node_key_data(
        leaves['very_absolute_key'],
        'very_absolute_key',
        occurrences:
          make_occurrences(
            [
              {
                path: 'app/controllers/events_controller.rb',
                pos: 160,
                line_num: 7,
                line_pos: 4,
                line: '    I18n.t("very_absolute_key")',
                raw_key: 'very_absolute_key'
              }
            ]
          )
      )

      expect_node_key_data(
        leaves['user_mailer.welcome_notification.subject'],
        'user_mailer.welcome_notification.subject',
        occurrences:
          make_occurrences(
            [
              {
                path: 'app/mailers/user_mailer.rb',
                pos: 113,
                line_num: 4,
                line_pos: 20,
                line: '      mail subject: default_i18n_subject',
                raw_key: 'user_mailer.welcome_notification.subject'
              }
            ]
          )
      )
    end
  end
end
