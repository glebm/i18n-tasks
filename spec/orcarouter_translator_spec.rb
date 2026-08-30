# frozen_string_literal: true

require "spec_helper"
require "i18n/tasks/commands"
require "i18n/tasks/translators/orcarouter_translator"
require "openai"

RSpec.describe "OrcaRouter Translation" do
  delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase
  let(:task) { i18n_task }

  before do
    TestCodebase.setup("config/locales/en.yml" => "", "config/locales/es.yml" => "")
  end

  after do
    TestCodebase.teardown
  end

  describe "stubbed test" do
    around do |example|
      original_value = ENV.fetch("ORCAROUTER_API_KEY", nil)
      ENV["ORCAROUTER_API_KEY"] = "stubbed_value"
      example.run
      ENV["ORCAROUTER_API_KEY"] = original_value
    end

    context "when translating to spanish" do
      it "translates missing keys via the OrcaRouter endpoint" do
        client = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).with(
          access_token: "stubbed_value",
          uri_base: "https://api.orcarouter.ai/v1",
          log_errors: true
        ).and_return(client)

        allow(client).to receive(:chat).with(
          parameters: {
            messages: array_including(
              hash_including(
                role: "system",
                content: a_string_including(
                  "translates content from the English locale to the Spanish locale in an i18n locale array"
                )
              ),
              hash_including(
                content: a_string_including("Translate this array:"),
                role: "user"
              ),
              hash_including(
                content: a_string_including("Hello, X__0 O'Neill!"),
                role: "user"
              )
            ),
            model: "orcarouter/fusion",
            response_format: {type: "json_object"},
            temperature: 0.0
          }
        ).and_return(
          "choices" => [
            {
              "message" => {
                "content" => {
                  "translations" => [
                    "¡Hola, X__0 O'Neill!"
                  ]
                }.to_json
              }
            }
          ]
        )

        in_test_app_dir do
          task.data[:en] = build_tree(
            "en" => {
              "common" => {
                "hello" => "Hello, %{user} O'Neill!"
              }
            }
          )
          task.data[:es] = build_tree("es" => {"placeholder" => "need something here"})
          run_cmd "translate-missing", "--backend=orcarouter", "--locales=es"

          expect(task.t("common.hello", "es")).to eq("¡Hola, %{user} O'Neill!")
        end
      end
    end

    context "when the API key is missing" do
      it "raises a helpful error" do
        allow(ENV).to receive(:fetch).with("ORCAROUTER_API_KEY", nil).and_return(nil)
        allow(ENV).to receive(:key?).and_call_original
        allow(ENV).to receive(:key?).with("ORCAROUTER_API_KEY").and_return(false)

        translator = I18n::Tasks::Translators::OrcaRouterTranslator.new(task)
        expect { translator.send(:api_key) }.to raise_error(
          ::I18n::Tasks::CommandError,
          /OrcaRouter API key/
        )
      end
    end
  end
end
