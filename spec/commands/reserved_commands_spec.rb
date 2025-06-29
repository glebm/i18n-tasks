# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Reserved commands" do
  delegate :run_cmd, :in_test_app_dir, to: :TestCodebase

  let(:base_keys) do
    {"a" => "hello %{object}", "b" => "foo %{bar}", "c" => {"d" => "hello %{object}"}, "e" => "ok"}
  end
  let(:test_keys) do
    {"a" => "hello %{object} %{format}", "b" => "foo %{bar}", "c" => {"d" => "hola %{object}"}, "e" => "ok"}
  end

  let(:wrong_subtree) do
    {"en" => {"a" => ["object"], "c" => {"d" => ["object"]}},
     "es" => {"a" => %w[object format], "c" => {"d" => ["object"]}}}
  end

  around do |ex|
    TestCodebase.setup(
      "config/i18n-tasks.yml" => {base_locale: "en", locales: %w[es]}.to_yaml,
      "config/locales/en.yml" => {"en" => base_keys}.to_yaml,
      "config/locales/es.yml" => {"es" => test_keys}.to_yaml
    )

    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe "#check_reserved_interpolations" do
    it "returns reserved keys" do
      expect(YAML.load(run_cmd("check-reserved-interpolations", "-fyaml"))).to eq(wrong_subtree)
    end
  end
end
