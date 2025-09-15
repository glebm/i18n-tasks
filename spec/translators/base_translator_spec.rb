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

  it "preserves successful translations when a subsequent slice fails" do
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

    # HTML slice should have been left untranslated due to simulated failure
    html = result.assoc("common.html.html")
    expect(html).not_to be_nil
    expect(html.last).to eq("<b>Hi</b>")
  end
end
