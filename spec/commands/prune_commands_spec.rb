# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Prune commands" do
  delegate :run_cmd, to: :TestCodebase

  let(:locale_data) do
    {
      "en" => {
        "hello" => "Hello",
        "en_only" => "This key exists only in English"
      },
      "fr" => {
        "hello" => "Bonjour",
        "fr_de" => "This key exists only in French and german"
      },
      "de" => {
        "hello" => "Hallo",
        "fr_de" => "This key exists only in French and german"
      },
      "es" => {
        "hello" => "Hello"
      }
    }
  end

  let(:config) { {base_locale: "en", locales: %w[en de fr es]} }

  around do |ex|
    TestCodebase.setup(
      "config/i18n-tasks.yml" => config.to_yaml,
      "config/locales/en.yml" => {"en" => locale_data["en"]}.to_yaml,
      "config/locales/de.yml" => {"de" => locale_data["de"]}.to_yaml,
      "config/locales/fr.yml" => {"fr" => locale_data["fr"]}.to_yaml,
      "config/locales/es.yml" => {"es" => locale_data["es"]}.to_yaml
    )
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  it "#prune" do
    run_cmd("prune", "--confirm")

    locale_data["fr"].delete("fr_de")
    locale_data["de"].delete("fr_de")

    expect(YAML.load_file("config/locales/en.yml")).to eq("en" => locale_data["en"])
    expect(YAML.load_file("config/locales/fr.yml")).to eq("fr" => locale_data["fr"])
    expect(YAML.load_file("config/locales/de.yml")).to eq("de" => locale_data["de"])
    expect(YAML.load_file("config/locales/es.yml")).to eq("es" => locale_data["es"])
  end

  it "prunes keys with --keep-order" do
    run_cmd("prune", "--confirm", "--keep-order")

    expect(YAML.load_file("config/locales/fr.yml")["fr"]).not_to have_key("fr_de")
    expect(YAML.load_file("config/locales/de.yml")["de"]).not_to have_key("fr_de")
    expect(YAML.load_file("config/locales/fr.yml")["fr"]).to have_key("hello")
    expect(YAML.load_file("config/locales/de.yml")["de"]).to have_key("hello")
  end

  context "with keys in non-alphabetical order" do
    let(:locale_data) do
      {
        "en" => {
          "zebra" => "Zebra",
          "apple" => "Apple",
          "mango" => "Mango"
        },
        "fr" => {
          "zebra" => "Zèbre",
          "apple" => "Pomme",
          "mango" => "Mangue",
          "fr_only" => "French only"
        }
      }
    end

    let(:config) { {base_locale: "en", locales: %w[en fr]} }

    it "preserves key order with --keep-order" do
      task = TestCodebase.i18n_task
      initial_keys = task.data["fr"]["fr"].children.map(&:key).reject { |k| k == "fr_only" }

      run_cmd("prune", "--confirm", "--keep-order")

      task.data.reload
      final_keys = task.data["fr"]["fr"].children.map(&:key)

      expect(final_keys).to eq(initial_keys)
    end
  end
end
