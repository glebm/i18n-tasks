# frozen_string_literal: true

require "spec_helper"

RSpec.describe "File system i18n" do
  describe "#available_locales" do
    before do
      TestCodebase.setup(
        "config/locales/en.yml" => {en: {}},
        "config/locales/es.yml" => {es: {}},
        "config/locales/other.fr.yml" => {fr: {}}
      )
    end

    after do
      TestCodebase.teardown
    end

    let(:data) { I18n::Tasks::Data::FileSystem.new }

    it "default pattern" do
      data.config = {read: ["config/locales/%{locale}.yml"]}
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[en es].sort)
      end
    end

    it "more inclusive pattern" do
      data.config = {read: ["config/locales/*%{locale}.yml"]}
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[en es fr].sort)
      end
    end

    it "another pattern" do
      data.config = {read: ["config/locales/*.%{locale}.yml"]}
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[fr].sort)
      end
    end
  end

  describe "#get" do
    let(:data) { I18n::Tasks::Data::FileSystem.new }

    after { TestCodebase.teardown }

    it "includes problematic YAML file path in exception message" do
      data.config = {read: ["invalid.yml"]}
      TestCodebase.setup("invalid.yml" => "%")
      TestCodebase.in_test_app_dir do
        expect { data.get(:invalid) }
          .to raise_error(I18n::Tasks::CommandError) do |error|
            expect(error.message).to end_with("(file: invalid.yml)")
          end
      end
    end

    it "includes problematic JSON file path in exception message" do
      data.config = {read: ["invalid.json"]}
      TestCodebase.setup("invalid.json" => "-")
      TestCodebase.in_test_app_dir do
        expect { data.get(:invalid) }
          .to raise_error(I18n::Tasks::CommandError) do |error|
            expect(error.message).to end_with("(file: invalid.json)")
          end
      end
    end

    describe "when a key is defined in several files" do
      before do
        TestCodebase.setup(
          "config/locales/a.en.yml" => {"en" => {"key" => "a"}}.to_yaml,
          "config/locales/b.en.yml" => {"en" => {"key" => "b"}}.to_yaml
        )
      end

      it "takes the value from the pattern listed last" do
        data.config = {read: ["config/locales/b.%{locale}.yml", "config/locales/a.%{locale}.yml"]}
        TestCodebase.in_test_app_dir { expect(data.get("en")["en.key"].value).to eq("a") }
      end

      it "takes the value from the file a pattern matches last" do
        data.config = {read: ["config/locales/*.%{locale}.yml"]}
        TestCodebase.in_test_app_dir { expect(data.get("en")["en.key"].value).to eq("b") }
      end
    end
  end

  describe "yml" do
    let(:data) { I18n::Tasks::Data::FileSystem.new }

    after { TestCodebase.teardown }

    it "#get" do
      data.config = {read: ["a.yml", "{b,c}.yml", "d.yml"]}
      TestCodebase.setup(
        "a.yml" => {en: {a: 1}}.stringify_keys.to_yaml,
        "b.yml" => {en: {b: 1}}.stringify_keys.to_yaml,
        "c.yml" => {en: {c: 1}}.stringify_keys.to_yaml,
        "d.yml" => <<~YAML
          ---
          en:
            d: &d test
            d_alias: *d
        YAML
      )
      TestCodebase.in_test_app_dir do
        actual = data[:en].to_hash["en"].symbolize_keys
        expect(actual).to eq(a: 1, b: 1, c: 1, d: "test", d_alias: "test")
      end
    end

    it "#set" do
      data.config = {read: "a.yml", write: [["{:}.*", '\1.%{locale}.yml']]}
      keys = {"a" => {"b" => "c"}, "x" => "y"}
      locale_data = {"pizza" => keys, "sushi" => keys}
      TestCodebase.setup
      TestCodebase.in_test_app_dir do
        data[:en] = data[:en].merge!({"en" => locale_data})
        files = %w[pizza.en.yml sushi.en.yml]
        expect(Dir["*.yml"].sort).to eq(files.sort)
        files.each { |f| expect(YAML.load_file(f)["en"]).to eq(File.basename(f, ".en.yml") => keys) }
      end
    end

    it "keeps the existing file when a write fails" do
      data.config = {read: "a.yml", write: ["a.yml"]}
      TestCodebase.setup("a.yml" => {en: {"a" => "1"}}.to_yaml)
      TestCodebase.in_test_app_dir do
        original = File.read("a.yml")
        allow(File).to receive(:atomic_write).and_wrap_original do |atomic_write, path, &block|
          atomic_write.call(path) do |file|
            file.write("partial content")
            raise Errno::ENOSPC
          end
        end
        expect { data[:en] = data[:en].merge!({"en" => {"b" => "2"}}) }.to raise_error(Errno::ENOSPC)
        expect(File.read("a.yml")).to eq(original)
      end
    end

    it "preserves the existing file permissions" do
      data.config = {read: "a.yml", write: ["a.yml"]}
      TestCodebase.setup("a.yml" => {en: {"a" => "1"}}.to_yaml)
      TestCodebase.in_test_app_dir do
        File.chmod(0o640, "a.yml")
        data[:en] = data[:en].merge!({"en" => {"b" => "2"}})
        expect(File.stat("a.yml").mode & 0o777).to eq(0o640)
      end
    end
  end

  describe "json" do
    let!(:data) do
      I18n::Tasks::Data::FileSystem.new(
        read: ["config/locales/%{locale}.json"],
        write: ["config/locales/%{locale}.json"]
      )
    end

    after { TestCodebase.teardown }

    it "reads" do
      data.config = {read: ["a.json", "{b,c}.json"]}
      TestCodebase.setup(
        "a.json" => {en: {a: 1}}.stringify_keys.to_json,
        "b.json" => {en: {b: 1}}.stringify_keys.to_json,
        "c.json" => {en: {c: 1}}.stringify_keys.to_json
      )
      TestCodebase.in_test_app_dir do
        expect(data[:en].to_hash["en"].symbolize_keys).to eq(a: 1, b: 1, c: 1)
      end
    end

    it "reads with json read options" do
      data.config = {read: ["a.json"], json: {read: {allow_trailing_comma: true}}}
      TestCodebase.setup("a.json" => '{"en": {"a": 1,}}')
      TestCodebase.in_test_app_dir do
        expect(data[:en].to_hash["en"]).to eq("a" => 1)
      end
    end

    it "writes" do
      data.config = {read: "a.json", write: [["{:}.*", '\1.%{locale}.json']]}
      keys = {"a" => {"b" => "c"}, "x" => "y"}
      locale_data = {"pizza" => keys, "sushi" => keys}
      TestCodebase.setup
      TestCodebase.in_test_app_dir do
        data[:en] = data[:en].merge!({"en" => locale_data})
        files = %w[pizza.en.json sushi.en.json]
        expect(Dir["*.json"].sort).to eq(files.sort)
        files.each do |f|
          expect(JSON.parse(File.read(f, encoding: "UTF-8"))["en"]).to eq(File.basename(f, ".en.json") => keys)
        end
      end
    end
  end
end
