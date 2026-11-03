# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Base Translator" do
  let(:task) { I18n::Tasks::BaseTask.new }

  # Create a fake translator that raises for html slices
  let(:translator_class) do
    Class.new(I18n::Tasks::Translators::BaseTranslator) do
      def translate_values(list, **options)
        if options[:html]
          raise StandardError, "html translation failure"
        end

        # return translated values simply by appending `-es` for testing
        list.map { |v| "#{v}-es" }
      end

      def options_for_translate_values(from:, to:, **options)
        options.merge(from: from, to: to)
      end

      def options_for_html
        {html: true}
      end

      def options_for_plain
        {html: false}
      end

      def no_results_error_message
        "no results"
      end
    end
  end

  it "preserves successful translations and skips failed slices" do
    translator = translator_class.new(task)

    list = [
      ["common.plain", "Hello"],
      ["common.html.html", "<b>Hi</b>"]
    ]

    result = translator.send(:translate_pairs, list, from: "en", to: "es")

    # Find translated plain key
    plain = result.assoc("common.plain")
    expect(plain).not_to be_nil
    expect(plain.last).to eq("Hello-es")

    # HTML slice failed and must not be written with the untranslated base value
    expect(result.assoc("common.html.html")).to be_nil
  end

  it "skips a slice when a provider returns an incomplete response" do
    translator = translator_class.new(task)
    allow(translator).to receive(:translate_values).and_return(["Hola"])

    result = translator.send(
      :translate_pairs,
      [["common.first", "Hello"], ["common.second", "Goodbye"]],
      from: "en",
      to: "es"
    )

    expect(result).to be_empty
  end

  it "skips a slice when a provider returns extra translations" do
    translator = translator_class.new(task)
    allow(translator).to receive(:translate_values).and_return(["Hola", "Adiós", "Extra"])

    result = translator.send(
      :translate_pairs,
      [["common.first", "Hello"], ["common.second", "Goodbye"]],
      from: "en",
      to: "es"
    )

    expect(result).to be_empty
  end

  it "keeps completed batches when a later batch fails" do
    translator = translator_class.new(task)
    first_batch = [["common.first", "Hello"]]
    failed_batch = [["common.second", "Goodbye"]]
    allow(translator).to receive(:translation_batches).and_return([first_batch, failed_batch])
    allow(translator).to receive(:translate_values) do |list, **|
      raise StandardError, "translation failure" if list == ["Goodbye"]

      list.map { |value| "#{value}-es" }
    end

    result = translator.send(
      :translate_pairs,
      first_batch + failed_batch,
      from: "en",
      to: "es"
    )

    expect(result).to eq([["common.first", "Hello-es"]])
  end
end
