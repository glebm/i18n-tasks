# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Unused keys" do
  let(:task) { I18n::Tasks::BaseTask.new }

  # https://github.com/glebm/i18n-tasks/issues/713
  # A leaf key usage (e.g. `t(:section)`) was shadowing/dropping nested keys under the
  # same root (e.g. `section.item.title`) when building the used-keys tree, causing those
  # nested keys to be falsely reported as unused.
  describe "issue #713: leaf key must not shadow nested keys with the same root" do
    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          "base_locale" => "en",
          "locales" => ["en"],
          "search" => {"paths" => ["app/"]}
        }.to_yaml,
        "config/locales/en.yml" => {
          "en" => {
            "section" => {
              "item" => {
                "title" => "Title",
                "subtitle" => "Subtitle"
              }
            }
          }
        }.to_yaml,
        "app/views/example.html.erb" => <<~ERB
          <%= t("section.item.title") %>
          <%= t("section.item.subtitle") %>
          <%= t(:section) %>
        ERB
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "does not report nested keys as unused when a leaf key shares the same root" do
      unused_key_names = task.unused_keys.key_names(root: true)
      expect(unused_key_names).not_to include("en.section.item.title")
      expect(unused_key_names).not_to include("en.section.item.subtitle")
    end
  end

  describe "#unused_keys" do
    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          "base_locale" => "en",
          "locales" => %w[en es],
          "search" => {"paths" => ["app/"]}
        }.to_yaml,
        "config/locales/en.yml" => {"en" => {"used" => "Used", "unused" => "Unused"}}.to_yaml,
        "config/locales/es.yml" => {"es" => {"used" => "Usado", "unused" => "No usado"}}.to_yaml,
        "app/views/example.html.erb" => %(<%= t("used") %>\n),
        "app/models/example.rb" => %(I18n.t("used")\n)
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "finds the used keys once for all the locales" do
      expect(task).to receive(:used_tree).once.and_call_original

      unused_key_names = task.unused_keys.key_names(root: true)

      expect(unused_key_names).to contain_exactly("en.unused", "es.unused")
    end

    it "parses the source once for the strict and the non-strict scans" do
      expect_any_instance_of(I18n::Tasks::Scanners::RubyScanner) # rubocop:disable RSpec/AnyInstance
        .to receive(:path_to_ast_and_comments).once.and_call_original

      task.unused_keys
    end
  end
end
