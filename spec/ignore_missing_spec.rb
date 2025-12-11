# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Ignore Missing" do
  let(:task) { I18n::Tasks::BaseTask.new }

  describe "with per-locale syntax" do
    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          base_locale: "en",
          locales: %w[en es fr de],
          ignore_missing: {
            "all" => ["common.ignored_for_all"],
            "es" => ["specific.ignored_for_es"],
            "es,fr" => ["specific.ignored_for_es_and_fr"]
          }
        }.to_yaml,
        "config/locales/en.yml" => {
          "en" => {
            "common" => {
              "ignored_for_all" => "Text",
              "not_ignored" => "Text"
            },
            "specific" => {
              "ignored_for_es" => "Text",
              "ignored_for_es_and_fr" => "Text"
            }
          }
        }.to_yaml,
        "config/locales/es.yml" => {"es" => {}}.to_yaml,
        "config/locales/fr.yml" => {"fr" => {}}.to_yaml,
        "config/locales/de.yml" => {"de" => {}}.to_yaml
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "ignores keys specified for all locales" do
      missing_keys = task.missing_keys(locales: ["es", "fr"])

      expect(missing_keys["es.common.ignored_for_all"]).to be_nil
      expect(missing_keys["fr.common.ignored_for_all"]).to be_nil
      expect(missing_keys["es.common.not_ignored"]).not_to be_nil
      expect(missing_keys["fr.common.not_ignored"]).not_to be_nil
    end

    it "ignores keys specified for specific locale (es only)" do
      missing_keys = task.missing_keys(locales: ["es", "fr"])

      expect(missing_keys["es.specific.ignored_for_es"]).to be_nil
      expect(missing_keys["fr.specific.ignored_for_es"]).not_to be_nil
    end

    it "ignores keys specified for multiple locales (es,fr)" do
      missing_keys = task.missing_keys(locales: ["es", "fr", "de"])

      expect(missing_keys["es.specific.ignored_for_es_and_fr"]).to be_nil
      expect(missing_keys["fr.specific.ignored_for_es_and_fr"]).to be_nil
      expect(missing_keys["de.specific.ignored_for_es_and_fr"]).not_to be_nil
    end
  end

  describe "backward compatibility with array syntax" do
    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          base_locale: "en",
          locales: %w[en es],
          ignore_missing: ["common.ignored"]
        }.to_yaml,
        "config/locales/en.yml" => {"en" => {"common" => {"ignored" => "Text"}}}.to_yaml,
        "config/locales/es.yml" => {"es" => {}}.to_yaml
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "still works with array syntax" do
      missing_keys = task.missing_keys(locales: ["es"])

      expect(missing_keys["es.common.ignored"]).to be_nil
    end
  end
end
