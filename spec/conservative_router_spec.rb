# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Conservative router" do
  describe "#available_locales" do
    before do
      TestCodebase.setup(
        "config/locales/en.yml" => {en: {a: 1}}.to_yaml,
        "config/locales/other.en.yml" => {
          en: {b: 1, d: {"" => "Blank", "with.dot" => "Dot"}, nested: {x: {y: 1}}}
        }.to_yaml,
        "config/locales/es.yml" => {es: {}}.to_yaml,
        "config/locales/other.es.yml" => {es: {c: 1, options: {"" => "Blank", "with.dot" => "Dot"}}}.to_yaml
      )
    end

    after do
      TestCodebase.teardown
    end

    let(:data) do
      I18n::Tasks::Data::FileSystem.new(
        router: "conservative_router",
        base_locale: "en",
        read: "config/locales/*%{locale}.yml",
        write: ["config/locales/not_found.%{locale}.yml"]
      )
    end

    it "preserves existing keys" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"]
        data.reload
        expect(data["es"]["es.c"].data[:path]).to eq("config/locales/other.es.yml")
      end
    end

    it "preserves existing keys that are blank or contain a dot" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"]
        data.reload
        options = data["es"]["es.options"].children
        expect(options.map(&:key)).to eq(["", "with.dot"])
        expect(options.map { |node| node.data[:path] }).to eq(["config/locales/other.es.yml"] * 2)
      end
    end

    it "infers new keys from base locale" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"].merge!(build_tree(es: {a: 1, b: 2}))
        data.reload
        expect(data["es"]["es.a"].data[:path]).to eq("config/locales/es.yml")
        expect(data["es"]["es.b"].data[:path]).to eq("config/locales/other.es.yml")
      end
    end

    it "infers new keys that are blank or contain a dot from base locale" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"].merge!(build_tree(es: {d: {"" => "Vacío", "with.dot" => "Punto"}}))
        data.reload
        expect(data["es"]["es.d"].children.map { |node| node.data[:path] }).to(
          eq(["config/locales/other.es.yml"] * 2)
        )
      end
    end

    it "infers new keys stored with a dot in one locale and nested in the other" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"].merge!(build_tree(es: {"nested.x" => {y: 2}}))
        data.reload
        nested_x = data["es"]["es"].children.find { |node| node.key == "nested.x" }
        expect(nested_x.children.map { |node| node.data[:path] }).to eq(["config/locales/other.es.yml"])
      end
    end

    it "falls back to pattern_router when the key is new" do
      TestCodebase.in_test_app_dir do
        data["es"] = data["es"].merge!(build_tree(es: {z: 2}))
        data.reload
        expect(data["es"]["es.z"].data[:path]).to eq("config/locales/not_found.es.yml")
      end
    end
  end
end
