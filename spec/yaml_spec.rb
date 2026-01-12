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

  describe "quote style configuration" do
    it "uses single quotes by default" do
      yaml = {"en" => {"key" => "value: with colon"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {})
      expect(result).to include("key: 'value: with colon'")
    end

    it "converts to double quotes when configured" do
      yaml = {"en" => {"key" => "value: with colon"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "double"})
      expect(result).to include('key: "value: with colon"')
    end

    it "keeps single quotes when quote is set to single" do
      yaml = {"en" => {"key" => "value: with colon"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "single"})
      expect(result).to include("key: 'value: with colon'")
    end

    it "uses prettier algorithm - prefers double when fewer escapes" do
      yaml = {"en" => {"key" => "it's: here"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "prettier"})
      expect(result).to include('key: "it\'s: here"')
    end

    it "uses prettier algorithm - keeps single when fewer escapes" do
      yaml = {"en" => {"key" => 'say "hello": world'}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "prettier"})
      expect(result).to include("key: 'say \"hello\": world'")
    end

    it "does not modify unquoted strings" do
      yaml = {"en" => {"simple" => "hello world"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "double"})
      expect(result).to include("simple: hello world")
    end

    it "handles nested structures" do
      yaml = {"en" => {"outer" => {"inner" => "value: nested"}}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "double"})
      expect(result).to include('inner: "value: nested"')
    end

    it "handles escaped single quotes in original" do
      yaml = {"en" => {"key" => "it's a 'test': here"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "double"})
      expect(result).to include('key: "it\'s a \'test\': here"')
    end

    it "converts single-quoted keys to double quotes with double setting" do
      yaml = {"en" => {"10" => "ten"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "double"})
      expect(result).to include('"10":')
    end

    it "converts single-quoted keys to double quotes with prettier setting" do
      yaml = {"en" => {"10" => "ten"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "prettier"})
      expect(result).to include('"10":')
    end

    it "keeps single-quoted keys when fewer escapes needed with prettier" do
      yaml = {"en" => {'say "hi": test' => "value"}}
      result = I18n::Tasks::Data::Adapter::YamlAdapter.dump(yaml, {quote: "prettier"})
      expect(result).to include("'say \"hi\": test':")
    end
  end
end
