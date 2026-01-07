# frozen_string_literal: true

require "spec_helper"
require "i18n/tasks/commands"
require "i18n/tasks/translators/anthropic_translator"
require "anthropic"

RSpec.describe "Anthropic Translation" do
  nil_value_test = ["nil-value-key", nil, nil]
  empty_value_test = ["empty-value-key", "", ""]
  text_test = ["hello", "Hello, %{user} O'Neill!", "¡Hola, %{user} O'Neill!"]
  text_test_multiline = [
    "hello_multiline",
    "Hello,\n%{user}\nO'Neill!",
    "¡Hola,\n%{user}\nO'Neill!"
  ]
  html_test = ["html-key.html", "Hello, <b>%{user} O'neill</b>", "Hola, <b>%{user} O'neill</b>"]
  html_test_plrl = ["html-key.html.one", "<b>Hello %{count}</b>", "<b>Hola %{count}</b>"]
  html_test_multiline = [
    "html-key.html.multiline_html",
    "<b>Hello</b>\n<b>%{user}</b>",
    "<b>Hola</b>\n<b>%{user}</b>"
  ]
  html_test_multiline_indentation = [
    "html-key.html.multiline_indentation_html",
    "<p>Hello</p>\n<ul>\n  <li>%{user}</li>\n  <li>\n    %{user2}\n  </li>\n  <li>Dog</li>\n<ul>\n",
    "<p>Hola</p>\n<ul>\n  <li>%{user}</li>\n  <li>\n    %{user2}\n  </li>\n  <li>Perro</li>\n<ul>\n"
  ]
  array_test = ["array-key", ["Hello.", nil, "", "Goodbye."], ["Hola.", nil, "", "Adiós."]]
  fixnum_test = ["numeric-key", 1, 1]
  ref_key_test = ["ref-key", :reference, :reference]

  delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase
  let(:task) { i18n_task }

  before do
    TestCodebase.setup("config/locales/en.yml" => "", "config/locales/es.yml" => "")
  end

  after do
    TestCodebase.teardown
  end

  describe "real world test" do
    it "translates all missing keys" do
      skip "ANTHROPIC_API_KEY env var not set" unless ENV["ANTHROPIC_API_KEY"]
      skip "ANTHROPIC_API_KEY env var is empty" if ENV["ANTHROPIC_API_KEY"].empty?
      in_test_app_dir do
        task.data[:en] = build_tree(
          "en" => {
            "common" => {
              "a" => "λ",
              "hello" => text_test[1],
              "hello_multiline" => text_test_multiline[1],
              "hello_html" => html_test[1],
              "hello_plural_html" => {
                "one" => html_test_plrl[1]
              },
              "hello_multiline_html" => html_test_multiline[1],
              "multiline_indentation_html" => html_test_multiline_indentation[1],
              "array_key" => array_test[1],
              "nil-value-key" => nil_value_test[1],
              "empty-value-key" => empty_value_test[1],
              "fixnum-key" => fixnum_test[1],
              "ref-key" => ref_key_test[1]
            }
          }
        )
        task.data[:es] = build_tree("es" => {
          "common" => {
            "a" => "λ"
          }
        })

        run_cmd "translate-missing", "--backend=anthropic"
        expect(task.t("common.hello", "es")).to eq(text_test[2])
        expect(task.t("common.hello_multiline", "es")).to eq(text_test_multiline[2])
        expect(task.t("common.hello_html", "es")).to eq(html_test[2])
        expect(task.t("common.hello_plural_html.one", "es")).to eq(html_test_plrl[2])
        expect(task.t("common.hello_multiline_html", "es")).to eq(html_test_multiline[2])
        expect(task.t("common.multiline_indentation_html", "es")).to eq(html_test_multiline_indentation[2])
        expect(task.t("common.array_key", "es")).to eq(array_test[2])
        expect(task.t("common.nil-value-key", "es")).to eq(nil_value_test[2])
        expect(task.t("common.empty-value-key", "es")).to eq(empty_value_test[2])
        expect(task.t("common.fixnum-key", "es")).to eq(fixnum_test[2])
        expect(task.t("common.ref-key", "es")).to eq(ref_key_test[2])
        expect(task.t("common.a", "es")).to eq("λ")
      end
    end
  end

  describe "stubbed test" do
    around do |example|
      original_value = ENV.fetch("ANTHROPIC_API_KEY", nil)
      ENV["ANTHROPIC_API_KEY"] = "stubbed_value"
      example.run
      ENV["ANTHROPIC_API_KEY"] = original_value
    end

    context "when translating to spanish" do
      it "translates missing" do
        client = instance_double(Anthropic::Client)
        messages_resource = instance_double("Anthropic::Resources::Messages")
        allow(Anthropic::Client).to receive(:new).and_return(client)
        allow(client).to receive(:messages).and_return(messages_resource)

        allow(messages_resource).to receive(:create).with(
          system_: a_string_including(
            "translates content from the English locale to the Spanish locale in an i18n locale array"
          ),
          messages: array_including(
            hash_including(
              content: a_string_including("Translate this array:"),
              role: "user"
            )
          ),
          model: "claude-3-5-haiku-20241022",
          max_tokens: 4096,
          temperature: 0.0
        ).and_return(
          "content" => [
            {
              "type" => "text",
              "text" => {
                "translations" => [
                  "¡Hola, X__0 O'Neill!"

                ]
              }.to_json
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
          run_cmd "translate-missing", "--backend=anthropic", "--locales=es"

          expect(task.t("common.hello", "es")).to eq("¡Hola, %{user} O'Neill!")
        end
      end
    end

    context "when translating to ukrainian" do
      before do
        TestCodebase.setup("config/locales/en.yml" => "", "config/locales/uk.yml" => "")
      end

      it "translates missing" do
        client = instance_double(Anthropic::Client)
        messages_resource = instance_double("Anthropic::Resources::Messages")
        allow(Anthropic::Client).to receive(:new).and_return(client)
        allow(client).to receive(:messages).and_return(messages_resource)

        allow(messages_resource).to receive(:create).with(
          system_: a_string_including("translates content from the English locale to the Ukrainian locale"),
          messages: array_including(
            hash_including(
              content: a_string_including("Translate this array:"),
              role: "user"
            )
          ),
          model: "claude-3-5-haiku-20241022",
          max_tokens: 4096,
          temperature: 0.0
        ).and_return(
          "content" => [
            {
              "type" => "text",
              "text" => {
                "translations" => [
                  "Привіт, X__0 O'Neill!"

                ]
              }.to_json
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
          task.data[:uk] = build_tree("uk" => {"placeholder" => "need something here"})
          run_cmd "translate-missing", "--backend=anthropic", "--locales=uk"

          expect(task.t("common.hello", "uk")).to eq("Привіт, %{user} O'Neill!")
        end
      end
    end

    context "when using per-locale prompts" do
      before do
        TestCodebase.setup(
          "config/locales/en.yml" => "",
          "config/locales/es.yml" => "",
          "config/i18n-tasks.yml" => {
            translation: {
              backend: :anthropic,
              anthropic_api_key: "stubbed_value",
              anthropic_locale_prompts: {
                es: "Custom Spanish prompt for %{from} to %{to}: Use informal language and Mexican expressions."
              }
            }
          }.to_yaml
        )
      end

      it "uses locale-specific prompt for Spanish" do
        client = instance_double(Anthropic::Client)
        messages_resource = instance_double("Anthropic::Resources::Messages")
        allow(Anthropic::Client).to receive(:new).and_return(client)
        allow(client).to receive(:messages).and_return(messages_resource)

        allow(messages_resource).to receive(:create).with(
          system_: a_string_including("Custom Spanish prompt for English to Spanish: Use informal language and Mexican expressions."),
          messages: array_including(
            hash_including(
              role: "user"
            )
          ),
          model: "claude-3-5-haiku-20241022",
          max_tokens: 4096,
          temperature: 0.0
        ).and_return(
          "content" => [
            {
              "type" => "text",
              "text" => {
                "translations" => [
                  "¡Órale, qué tal X__0!"
                ]
              }.to_json
            }
          ]
        )

        in_test_app_dir do
          task.data[:en] = build_tree(
            "en" => {
              "common" => {
                "hello" => "Hello, %{user}!"
              }
            }
          )
          task.data[:es] = build_tree("es" => {"placeholder" => "need something here"})
          run_cmd "translate-missing", "--backend=anthropic", "--locales=es"

          expect(task.t("common.hello", "es")).to eq("¡Órale, qué tal %{user}!")
        end
      end

      it "falls back to default prompt for locales without custom prompts" do
        client = instance_double(Anthropic::Client)
        messages_resource = instance_double("Anthropic::Resources::Messages")
        allow(Anthropic::Client).to receive(:new).and_return(client)
        allow(client).to receive(:messages).and_return(messages_resource)

        allow(messages_resource).to receive(:create).with(
          system_: a_string_including("You are a professional translator that translates content from the English locale to the French locale"),
          messages: array_including(
            hash_including(
              role: "user"
            )
          ),
          model: "claude-3-5-haiku-20241022",
          max_tokens: 4096,
          temperature: 0.0
        ).and_return(
          "content" => [
            {
              "type" => "text",
              "text" => {
                "translations" => [
                  "Bonjour, X__0!"
                ]
              }.to_json
            }
          ]
        )

        TestCodebase.setup(
          "config/locales/en.yml" => "",
          "config/locales/fr.yml" => ""
        )

        in_test_app_dir do
          task.data[:en] = build_tree(
            "en" => {
              "common" => {
                "hello" => "Hello, %{user}!"
              }
            }
          )
          task.data[:fr] = build_tree("fr" => {"placeholder" => "need something here"})
          run_cmd "translate-missing", "--backend=anthropic", "--locales=fr"

          expect(task.t("common.hello", "fr")).to eq("Bonjour, %{user}!")
        end
      end
    end
  end
end
