# frozen_string_literal: true

require "spec_helper"

# A locale file can hold several locales: an `all.yml`, `en-GB` keys in `en.yml`, or files named without a locale.
# Writing one locale must keep the others.
RSpec.describe "Files holding several locales" do
  after { TestCodebase.teardown }

  def setup_app(config, files)
    TestCodebase.setup(
      {"config/i18n-tasks.yml" => {"base_locale" => "en"}.merge(config).to_yaml,
       "app/views/index.html.erb" => %(<%= t("hello") %>\n<%= t("a") %>\n)}
        .merge(files.to_h { |name, data| ["config/locales/#{name}", data.to_yaml] })
    )
  end

  def locale_files
    TestCodebase.in_test_app_dir do
      Dir["config/locales/*"].sort.to_h { |path| [File.basename(path), YAML.load_file(path)] }
    end
  end

  describe "with data.read file names without a locale" do
    before do
      setup_app({"locales" => %w[en es], "data" => {"read" => %w[config/locales/english.yml config/locales/spanish.yml]}},
        "english.yml" => {"en" => {"hello" => "Hello", "bye" => "Bye"}},
        "spanish.yml" => {"es" => {"hello" => "Hola"}})
    end

    it "keeps every key with add-missing" do
      TestCodebase.run_cmd "add-missing"
      expect(locale_files["english.yml"]["en"]).to include("hello" => "Hello", "bye" => "Bye")
      expect(locale_files["spanish.yml"]["es"]).to include("hello" => "Hola")
    end
  end

  describe "with en-GB keys in en.yml" do
    before do
      setup_app({"locales" => %w[en]},
        "en.yml" => {"en" => {"hello" => "Hello", "bye" => "Bye"}, "en-GB" => {"hello" => "Hello GB", "bye" => "Bye GB"}})
    end

    it "keeps them with normalize" do
      TestCodebase.run_cmd "normalize"
      expect(locale_files).to eq("en.yml" => {"en" => {"bye" => "Bye", "hello" => "Hello"},
                                              "en-GB" => {"bye" => "Bye GB", "hello" => "Hello GB"}})
    end

    it "removes a key from them in place with rm" do
      TestCodebase.run_cmd "rm", "bye"
      expect(locale_files).to eq("en.yml" => {"en" => {"hello" => "Hello"}, "en-GB" => {"hello" => "Hello GB"}})
    end

    it "removes their last key with remove-unused" do
      TestCodebase.in_test_app_dir do
        File.write("config/locales/en.yml", {"en" => {"hello" => "Hello", "bye" => "Bye"}, "en-GB" => {"bye" => "Bye GB"}}.to_yaml)
      end
      TestCodebase.run_cmd "remove-unused", "-y"
      expect(locale_files).to eq("en.yml" => {"en" => {"hello" => "Hello"}})
    end

    it "removes their last key with rm" do
      TestCodebase.in_test_app_dir do
        File.write("config/locales/en.yml", {"en" => {"hello" => "Hello", "bye" => "Bye"}, "en-GB" => {"bye" => "Bye GB"}}.to_yaml)
      end
      TestCodebase.run_cmd "rm", "bye"
      expect(locale_files).to eq("en.yml" => {"en" => {"hello" => "Hello"}})
    end

    it "moves a key within them in place with mv" do
      TestCodebase.run_cmd "mv", "bye", "farewell"
      expect(locale_files).to eq("en.yml" => {"en" => {"farewell" => "Bye", "hello" => "Hello"},
                                              "en-GB" => {"farewell" => "Bye GB", "hello" => "Hello GB"}})
    end
  end

  describe "with keys of a configured locale in another locale's file" do
    before do
      setup_app({"locales" => %w[en en-GB fr]},
        "en.yml" => {"en" => {"hello" => "Hello", "bye" => "Bye"}, "en-GB" => {"bye" => "Bye GB"}},
        "fr.yml" => {"fr" => {"hello" => "Bonjour"}, "en" => {"legacy" => "Legacy"}})
    end

    it "removes them with rm" do
      TestCodebase.run_cmd "rm", "bye", "legacy"
      expect(locale_files).to eq("en.yml" => {"en" => {"hello" => "Hello"}}, "fr.yml" => {"fr" => {"hello" => "Bonjour"}})
    end
  end

  describe "with every locale in all.yml" do
    before do
      setup_app({"locales" => %w[en fr], "data" => {"read" => ["config/locales/all.yml"]}},
        "all.yml" => {"en" => {"hello" => "Hello", "bye" => "Bye"}, "fr" => {"hello" => "Bonjour"}})
    end

    it "keeps the other locales with add-missing" do
      TestCodebase.run_cmd "add-missing"
      expect(locale_files["all.yml"]).to eq("en" => {"bye" => "Bye", "hello" => "Hello"},
        "fr" => {"bye" => "Bye", "hello" => "Bonjour"})
    end

    it "adds missing keys to every locale with add-missing" do
      TestCodebase.in_test_app_dir do
        File.write("config/locales/all.yml", {"en" => {"hello" => "Hello"}, "fr" => {"x" => "X"}}.to_yaml)
      end
      TestCodebase.run_cmd "add-missing"
      expect(locale_files["all.yml"]).to eq("en" => {"hello" => "Hello", "x" => "X"}, "fr" => {"hello" => "Hello", "x" => "X"})
    end

    it "keeps the other locales with rm" do
      TestCodebase.run_cmd "rm", "bye"
      expect(locale_files).to eq("all.yml" => {"en" => {"hello" => "Hello"}, "fr" => {"hello" => "Bonjour"}})
    end

    it "keeps the other locales with mv" do
      TestCodebase.run_cmd "mv", "bye", "farewell"
      expect(locale_files["all.yml"]).to eq("en" => {"hello" => "Hello"}, "fr" => {"hello" => "Bonjour"})
    end

    it "keeps the other locales with data-write" do
      TestCodebase.in_test_app_dir do
        I18n::Tasks::BaseTask.new.data.write(I18n::Tasks::Data::Tree::Siblings.from_nested_hash(
          "en" => {"hello" => "Hi"}, "fr" => {"hello" => "Salut"}
        ))
      end
      expect(locale_files).to eq("all.yml" => {"en" => {"hello" => "Hi"}, "fr" => {"hello" => "Salut"}})
    end

    it "removes the last key of a locale with rm" do
      TestCodebase.in_test_app_dir do
        File.write("config/locales/all.yml", {"en" => {"hello" => "Hello", "bye" => "Bye"}, "fr" => {"bye" => "Au revoir"}}.to_yaml)
      end
      TestCodebase.run_cmd "rm", "bye"
      expect(locale_files).to eq("all.yml" => {"en" => {"hello" => "Hello"}})
    end

    it "finds the file normalized after normalize" do
      TestCodebase.run_cmd "normalize"
      expect(TestCodebase.run_cmd("check-normalized")).not_to include("all.yml")
    end
  end

  describe "with a blank file among the targets" do
    before do
      setup_app({"locales" => %w[en],
                 "data" => {"write" => [["devise.*", "config/locales/devise.%{locale}.json"], "config/locales/%{locale}.yml"]}},
        "en.yml" => {"en" => {"hello" => "Hello", "devise" => {"a" => "A"}}})
      TestCodebase.in_test_app_dir { File.write("config/locales/devise.en.json", " \n") }
    end

    it "overwrites it" do
      TestCodebase.run_cmd "normalize", "--pattern_router"
      expect(TestCodebase.in_test_app_dir { JSON.parse(File.read("config/locales/devise.en.json")) })
        .to eq("en" => {"devise" => {"a" => "A"}})
    end
  end

  describe "with a file that fails to parse among the targets" do
    before do
      setup_app({"locales" => %w[en],
                 "data" => {"write" => [["devise.*", "config/locales/devise.%{locale}.yml"], "config/locales/%{locale}.yml"]}},
        "en.yml" => {"en" => {"hello" => "Hello", "devise" => {"a" => "A"}}})
      TestCodebase.in_test_app_dir { File.write("config/locales/devise.en.yml", "%") }
    end

    it "overwrites it, as before" do
      TestCodebase.run_cmd "normalize", "--pattern_router"
      expect(locale_files).to eq("devise.en.yml" => {"en" => {"devise" => {"a" => "A"}}}, "en.yml" => {"en" => {"hello" => "Hello"}})
    end

    it "finds it not normalized" do
      TestCodebase.in_test_app_dir do
        config = YAML.load_file("config/i18n-tasks.yml")
        File.write("config/i18n-tasks.yml", config.merge("data" => config["data"].merge("router" => "pattern_router")).to_yaml)
      end
      expect(TestCodebase.run_cmd("check-normalized")).to include("devise.en.yml")
    end
  end
end
