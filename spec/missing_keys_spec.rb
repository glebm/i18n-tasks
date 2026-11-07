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

  describe "#missing_used_forest" do
    it "finds the used keys once for all the locales" do
      i18n = I18n::Tasks::BaseTask.new
      allow(i18n).to receive(:scanner).and_return(double(keys: [])) # rubocop:disable RSpec/VerifiedDoubles

      expect(i18n).to receive(:used_tree).once.and_call_original

      i18n.missing_used_forest(%w[en es])
    end
  end

  describe "plural detection from scanner" do
    let(:i18n) { I18n::Tasks::BaseTask.new }
    let(:plural_config) do
      {
        en: {
          i18n: {
            plural: {
              keys: %i[one other],
              rule: -> {}
            }
          }
        }
      }
    end
    let(:locale_data_with_partial_plural) do
      {"en" => {"en" => {"foo" => {"one" => "One"}}}}
    end

    before do
      allow(i18n).to receive_messages(load_rails_i18n_pluralization!: plural_config, external_key?: false, ignore_key?: false)
      allow(i18n).to receive(:prism_scanner_active?).and_return(true)
      allow(i18n).to receive(:data) do
        double("data").tap do |d| # rubocop:disable RSpec/VerifiedDoubles
          allow(d).to receive(:[]) do |locale|
            ::I18n::Tasks::Data::Tree::Siblings.from_nested_hash(
              locale_data_with_partial_plural[locale] || {}
            )
          end
        end
      end
    end

    def make_plural_source_map(key, plural_value)
      occ = ::I18n::Tasks::Scanners::Results::Occurrence.new(
        path: "app/views/example.html.erb",
        line: "t('#{key}')",
        pos: 0, line_pos: 0, line_num: 1,
        raw_key: key,
        plural: plural_value
      )
      {key => [occ]}
    end

    context "when a key is used only without count: (Prism scanner, plural: false)" do
      it "does not report missing plural forms" do
        allow(i18n).to receive(:source_key_occurrences_map).and_return(make_plural_source_map("foo", false))

        missing = i18n.missing_plural_forest(%w[en])
        expect(missing.leaves.to_a).to be_empty
      end
    end

    context "when a key is used with count: (Prism scanner, plural: true)" do
      it "reports missing plural forms" do
        allow(i18n).to receive(:source_key_occurrences_map).and_return(make_plural_source_map("foo", true))

        missing = i18n.missing_plural_forest(%w[en])
        missing_keys = missing.leaves.map { |l| l.full_key(root: false) }
        expect(missing_keys).to include("foo")
      end
    end

    context "when a key is not in the source" do
      it "still reports missing plural forms (conservative: absent keys are always checked)" do
        allow(i18n).to receive(:source_key_occurrences_map).and_return({})

        missing = i18n.missing_plural_forest(%w[en])
        missing_keys = missing.leaves.map { |l| l.full_key(root: false) }
        expect(missing_keys).to include("foo")
      end
    end

    context "when scanner produces nil plural (non-Prism scanner)" do
      it "still reports missing plural forms (backward-compatible behavior)" do
        allow(i18n).to receive(:source_key_occurrences_map).and_return(make_plural_source_map("foo", nil))

        missing = i18n.missing_plural_forest(%w[en])
        missing_keys = missing.leaves.map { |l| l.full_key(root: false) }
        expect(missing_keys).to include("foo")
      end
    end

    it "does not scan source files without Prism" do
      allow(i18n).to receive(:prism_scanner_active?).and_return(false)

      expect(i18n).not_to receive(:source_key_occurrences_map)

      i18n.missing_plural_forest(%w[en])
    end

    describe "#source_key_occurrences_map" do
      def occurrence_for(key, candidate_keys: [key])
        ::I18n::Tasks::Scanners::Results::Occurrence.new(
          path: "app/views/example.html.erb",
          line: "t('#{key}')",
          pos: 0, line_pos: 0, line_num: 1,
          raw_key: key,
          candidate_keys: candidate_keys
        )
      end

      def used_tree_from(*key_occurrences)
        children = ::I18n::Tasks::Data::Tree::Siblings.from_key_occurrences(key_occurrences)
        ::I18n::Tasks::Data::Tree::Node.new(key: "used", children: children).to_siblings
      end

      it "includes occurrences on parent nodes" do
        parent_occurrence = occurrence_for("foo")
        child_occurrence = occurrence_for("foo.one")
        tree = used_tree_from(
          ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: "foo", occurrences: [parent_occurrence]),
          ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: "foo.one", occurrences: [child_occurrence])
        )
        allow(i18n).to receive_messages(used_in_source_tree: tree, used_tree: tree)

        expect(i18n.send(:source_key_occurrences_map)["foo"]).to include(parent_occurrence)
      end

      it "indexes resolved keys without replacing direct occurrences" do
        direct_occurrence = occurrence_for("foo")
        resolved_occurrence = occurrence_for("label", candidate_keys: ["label"])
        source_tree = used_tree_from(
          ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: "foo", occurrences: [direct_occurrence])
        )
        resolved_tree = used_tree_from(
          ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: "foo", occurrences: [resolved_occurrence])
        )
        allow(i18n).to receive_messages(used_in_source_tree: source_tree, used_tree: resolved_tree)

        expect(i18n.send(:source_key_occurrences_map)["foo"]).to contain_exactly(direct_occurrence, resolved_occurrence)
      end
    end

    it "matches dynamic keys with braces in their interpolation" do
      expect(i18n.send(:dynamic_key_matches?, "items.\#{ {type: :book}[:type] }", "items.book")).to be(true)
    end
  end
end
