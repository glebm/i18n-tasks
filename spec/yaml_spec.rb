# frozen_string_literal: true

require "spec_helper"

RSpec.describe "YAML spec" do
  describe "emoji retention" do
    let(:yaml) do
      {
        "a" => "hello %{world}😀",
        "b" => "foo",
        "c" => {
          "d" => "hello %{name}"
        },
        "e" => "ok"
      }
    end

    it "does not strip emojis from yaml" do
      dumped_yaml = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {})
      expect(dumped_yaml).to include("😀")
    end
  end

  describe "parsing multiline" do
    # https://yaml-multiline.info
    # This spec checks the behaviour of parsing and dumping multiline strings
    # It would be preferable if we could get the same symbols used after dumping
    # But this is the default YAML behaviour.
    let(:source) do
      <<~YAML
        ---
        en:
          literal: |
            hello
            world

            newline
          literal_strip: |-
            hello
            world

            newline
          literal_keep: |+
            hello
            world

            newline
          folded: >
            hello
            world

            newline
          folded_strip: >-
            hello
            world

            newline
          folded_keep: >+
            hello
            world

            newline
      YAML
    end

    it "parses multiline strings" do
      parsed = I18n::Tasks::Data::Adapter::YamlAdapter.parse(source, {})

      expect(parsed.dig("en", "literal")).to eq("hello\nworld\n\nnewline\n")
      expect(parsed.dig("en", "literal_strip")).to eq("hello\nworld\n\nnewline")
      expect(parsed.dig("en", "literal_keep")).to eq("hello\nworld\n\nnewline\n")
      expect(parsed.dig("en", "folded")).to eq("hello world\nnewline\n")
      expect(parsed.dig("en", "folded_strip")).to eq("hello world\nnewline")
      expect(parsed.dig("en", "folded_keep")).to eq("hello world\nnewline\n")

      expected = <<~YAML
        ---
        en:
          literal: |
            hello
            world

            newline
          literal_strip: |-
            hello
            world

            newline
          literal_keep: |
            hello
            world

            newline
          folded: |
            hello world
            newline
          folded_strip: |-
            hello world
            newline
          folded_keep: |
            hello world
            newline
      YAML

      dumped = I18n::Tasks::Data::Adapter::YamlAdapter.dump(parsed, {})
      expect(dumped).to eq(expected)
    end
  end
end
