# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Missing commands" do
  delegate :run_cmd, to: :TestCodebase

  let(:missing_keys) { {"a" => "A", "ref" => :ref} }
  let(:config) { {base_locale: "en", locales: %w[es fr]} }

  around do |ex|
    TestCodebase.setup(
      "config/i18n-tasks.yml" => config.to_yaml,
      "config/locales/es.yml" => {"es" => missing_keys}.to_yaml
    )
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe "#add_missing" do
    describe "adds the missing keys to base locale first, then to other locales" do
      it "with -v argument" do
        run_cmd "add-missing", "-vTRME"
        created_keys = missing_keys.dup
        created_keys["a"] = "TRME"
        expect(YAML.load_file("config/locales/en.yml")).to eq("en" => created_keys)
        expect(YAML.load_file("config/locales/fr.yml")).to eq("fr" => created_keys)
      end
    end
  end

  describe "#missing" do
    describe "returns missing keys" do
      it "with -t diff argument" do
        expect(YAML.load(run_cmd("missing", "-tdiff", "-fyaml"))).to eq("en" => missing_keys)
      end

      it "with -t used argument" do
        expect(YAML.load(run_cmd("missing", "-tused", "-fyaml"))).to eq({})
      end

      it "with -t plural argument" do
        expect(YAML.load(run_cmd("missing", "-tplural", "-fyaml"))).to eq({})
      end

      it "with invalid -t argument" do
        expect { run_cmd "missing", "-tinvalid" }.to raise_error(I18n::Tasks::CommandError)
      end
    end
  end

  describe "#translate_missing" do
    it "defaults the backend to google when not specified" do
      google_double = instance_double(I18n::Tasks::Translators::GoogleTranslator)
      allow(I18n::Tasks::Translators::GoogleTranslator).to receive(:new).and_return(google_double)
      allow(google_double).to receive(:translate_forest).and_return(I18n::Tasks::BaseTask.new.empty_forest)
      expect(google_double).to receive(:translate_forest)

      run_cmd "translate-missing"
    end

    it "errors when invalid backend is specified" do
      invalid = "awesome-translate"

      expect { run_cmd "translate-missing", "-b #{invalid}" }.to(
        raise_error(
          I18n::Tasks::CommandError,
          I18n.t("i18n_tasks.cmd.errors.invalid_backend",
            invalid: invalid, valid: I18n::Tasks::Command::Options::Locales::TRANSLATION_BACKENDS * ", ")
        )
      )
    end

    context "when backend is specified in config" do
      let(:config) { {base_locale: "en", locales: %w[es fr], translation: {backend: "deepl"}} }

      it "uses the backend from the configuration" do
        deepl_double = instance_double(I18n::Tasks::Translators::DeeplTranslator)
        allow(I18n::Tasks::Translators::DeeplTranslator).to receive(:new).and_return(deepl_double)
        allow(deepl_double).to receive(:translate_forest).and_return(I18n::Tasks::BaseTask.new.empty_forest)
        expect(deepl_double).to receive(:translate_forest)

        run_cmd "translate-missing"
      end
    end
  end
end
