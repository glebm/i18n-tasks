# frozen_string_literal: true

require "spec_helper"

RSpec.describe "MissingKeys" do
  describe "#required_plural_keys_for_locale(locale)" do
    let(:task) { I18n::Tasks::BaseTask.new }

    def configuration_from(locale)
      {
        "#{locale}": {
          i18n: {
            plural: {
              keys: %i[one other],
              rule: -> {}
            }
          }
        }
      }
    end

    context "when country code is lowercase" do
      let(:locale) { "en-gb" }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale).and_return(configuration)
      end

      it "accesses the capitalized country code key and returns a populated set" do
        expect(task.required_plural_keys_for_locale(locale)).not_to be_empty
      end
    end

    context "when country code is uppercase" do
      let(:locale) { "en-GB" }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale.downcase).and_return(configuration)
      end

      it "accesses the capitalized country code key and returns a populated set" do
        expect(task.required_plural_keys_for_locale(locale.downcase)).not_to be_empty
      end
    end

    context "when country code consists of three letters" do
      let(:locale) { "zh-YUE" }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale.downcase).and_return(configuration)
      end

      it "accesses the country code key and returns a populated set" do
        expect(task.required_plural_keys_for_locale(locale.downcase)).not_to be_empty
      end
    end

    context "when locale is not present in configuration hash" do
      let(:locale) { "zz-zz" }
      let(:configuration) { configuration_from("en-us") }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale).and_return(configuration)
      end

      it "returns an empty set" do
        expect(task.required_plural_keys_for_locale(locale)).to be_empty
      end
    end
  end

  describe "candidate keys in occurrences" do
    it "does not report a usage missing if any candidate key exists in locale" do
      i18n = I18n::Tasks::BaseTask.new

      # simulate that locale 'en' contains 'events.success' but not 'events.create.success'
      allow(i18n).to receive(:key_value?) do |key, locale|
        key == "events.success"
      end
      allow(i18n).to receive(:external_key?).and_return(false)

      # Create an occurrence and attach candidate keys like the Prism scanner would
      occ = make_occurrence(path: "app/controllers/events_controller.rb", line: "t('.success')", line_num: 10, raw_key: ".success")
      occ.instance_variable_set(:@candidate_keys, ["events.create.success", "events.success"])

      key_occ = ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: "events.create.success", occurrences: [occ])

      # Stub the scanner to return our key occurrence
      allow(i18n).to receive_messages(external_key?: false, scanner: double(keys: [key_occ])) # rubocop:disable RSpec/VerifiedDoubles

      missing = i18n.missing_used_forest(%w[en])

      expect(missing.leaves.to_a).to be_empty
    end
  end

  describe "ActiveModel#human_attribute_name with Prism scanner (rails)" do
    let(:task) { I18n::Tasks::BaseTask.new }

    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          base_locale: "en",
          locales: %w[en],
          search: {paths: %w[app/], prism: "rails"}
        }.to_yaml,
        "app/models/pure_active_model.rb" => <<~RUBY,
          class PureActiveModel
            include ActiveModel::Model
            attr_accessor :code
          end

          PureActiveModel.human_attribute_name(:code)
        RUBY
        "config/locales/en.yml" => {
          "en" => {
            "activemodel" => {
              "attributes" => {"pure_active_model" => {"code" => "Code"}}
            }
          }
        }.to_yaml
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "does not report the attribute as missing when translation exists under activemodel.*" do
      missing_keys = task.missing_keys(locales: ["en"])

      expect(missing_keys["en.activerecord.attributes.pure_active_model.code"]).to be_nil
    end
  end
end
