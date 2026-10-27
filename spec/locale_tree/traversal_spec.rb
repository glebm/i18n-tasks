# frozen_string_literal: true

require "spec_helper"

RSpec.describe I18n::Tasks::Data::Tree::Traversal do
  delegate :i18n_task, to: :TestCodebase

  before do
    TestCodebase.setup fixtures_contents
  end

  after do
    TestCodebase.teardown
  end

  describe "#grep_keys" do
    it "returns Siblings" do
      expect(i18n_task.data["en"].grep_keys(/key/)).to be_a(I18n::Tasks::Data::Tree::Siblings)
    end
  end

  describe "#select_nodes" do
    it "copies each selected node once" do
      tree = build_tree(a: {b: {c: {d: 1}}})
      expect(I18n::Tasks::Data::Tree::Node).to receive(:new).exactly(4).times.and_call_original

      selected = tree.select_nodes { true }

      expect(selected.to_hash).to eq("a" => {"b" => {"c" => {"d" => 1}}})
      expect(selected["a.b.c"].parent).to equal(selected["a.b"])
    end
  end

  describe "#set_each_value!" do
    it "keeps array, number and boolean values, even empty or false, when the pattern is a lone placeholder" do
      values = {"steps" => ["One", "Two"], "count" => 3, "enabled" => true, "disabled" => false, "none" => []}
      tree = build_tree("es" => values)

      tree.set_each_value!("%{value_or_default_or_human_key}")

      expect(tree.to_hash).to eq("es" => values)
    end

    it "still interpolates them into a longer pattern" do
      tree = build_tree("es" => {"steps" => ["One", "Two"]})

      tree.set_each_value!("TRME %{value}")

      expect(tree.to_hash).to eq("es" => {"steps" => 'TRME ["One", "Two"]'})
    end
  end
end
