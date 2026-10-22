# frozen_string_literal: true

require "spec_helper"
require "i18n/tasks/commands"
require "i18n/tasks/translators/claude_code_translator"

RSpec.describe "Claude Code Translation" do
  delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase
  let(:task) { i18n_task }
  let(:translator) { I18n::Tasks::Translators::ClaudeCodeTranslator.new(task) }
  let(:success) { instance_double(Process::Status, success?: true) }
  let(:failure) { instance_double(Process::Status, success?: false) }

  def cli_output(translations)
    {"type" => "result", "is_error" => false, "structured_output" => {"translations" => translations}}.to_json
  end

  before do
    TestCodebase.setup("config/locales/en.yml" => "", "config/locales/es.yml" => "")
  end

  after do
    TestCodebase.teardown
  end

  describe "real world test" do
    it "translates through the local CLI" do
      skip "CLAUDE_CODE_TRANSLATE_TEST env var not set" unless ENV["CLAUDE_CODE_TRANSLATE_TEST"]
      in_test_app_dir do
        task.data[:en] = build_tree("en" => {"common" => {"hello" => "Hello, %{user}!", "html" => "<b>Save</b>"}})
        task.data[:es] = build_tree("es" => {"placeholder" => "need something here"})

        run_cmd "translate-missing", "--backend=claude_code", "--locales=es"

        expect(task.t("common.hello", "es")).to include("%{user}")
        expect(task.t("common.html", "es")).to match(%r{\A<b>.+</b>\z})
      end
    end
  end

  describe "stubbed test" do
    it "translates missing keys" do
      allow(Open3).to receive(:capture3).and_return([cli_output(["¡Hola, X__0 O'Neill!"]), "", success])

      in_test_app_dir do
        task.data[:en] = build_tree("en" => {"common" => {"hello" => "Hello, %{user} O'Neill!"}})
        task.data[:es] = build_tree("es" => {"placeholder" => "need something here"})
        run_cmd "translate-missing", "--backend=claude_code", "--locales=es"

        expect(task.t("common.hello", "es")).to eq("¡Hola, %{user} O'Neill!")
      end
    end

    it "passes the prompt, schema, and default model, with values on stdin" do
      expect(Open3).to receive(:capture3) do |*args, stdin_data:|
        expect(args).to start_with("claude", "-p")
        expect(args.each_cons(2)).to include(["--model", "claude-sonnet-5-5"])
        schema = I18n::Tasks::Translators::ClaudeCodeTranslator::OUTPUT_SCHEMA.to_json
        expect(args.each_cons(2)).to include(["--json-schema", schema])
        expect(args.each_cons(2)).to include(["--tools", ""])
        expect(args).not_to include("--bare", "--effort")
        system_prompt = args[args.index("--system-prompt") + 1]
        expect(system_prompt).to include("from the English locale to the Spanish locale")
        expect(stdin_data).to include(["Hello"].to_json)
        [cli_output(["Hola"]), "", success]
      end

      expect(translator.send(:request_translations, translator.send(:system_prompt, "en", "es"), ["Hello"]))
        .to eq(["Hola"])
    end

    it "uses the configured model, effort, and executable" do
      task.config = {translation: {claude_model: "claude-opus-5-5", claude_effort: "low",
                                   claude_code_executable: "/opt/bin/claude"}}

      expect(Open3).to receive(:capture3) do |*args, **|
        expect(args.first).to eq("/opt/bin/claude")
        expect(args.each_cons(2)).to include(["--model", "claude-opus-5-5"], ["--effort", "low"])
        [cli_output(["Hola"]), "", success]
      end

      translator.send(:request_translations, "prompt", ["Hello"])
    end

    it "uses a per-locale prompt" do
      task.config = {translation: {claude_locale_prompts: {"es" => "Translate %{from} into Mexican %{to}."}}}

      expect(translator.send(:system_prompt, "en", "es")).to eq("Translate English into Mexican Spanish.")
    end

    it "raises the CLI's error message" do
      output = {"is_error" => true, "result" => "There's an issue with the selected model"}.to_json
      allow(Open3).to receive(:capture3).and_return([output, "", failure])

      expect { translator.send(:request_translations, "prompt", ["Hello"]) }
        .to raise_error(RuntimeError, /Claude Code failed: There's an issue with the selected model/)
    end

    it "raises stderr when the output is not JSON" do
      allow(Open3).to receive(:capture3).and_return(["", "not logged in", failure])

      expect { translator.send(:request_translations, "prompt", ["Hello"]) }
        .to raise_error(RuntimeError, /unexpected output: not logged in/)
    end

    it "explains how to install the CLI when it is missing" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

      expect { translator.send(:request_translations, "prompt", ["Hello"]) }
        .to raise_error(I18n::Tasks::CommandError, /Claude Code CLI not found/)
    end
  end
end
