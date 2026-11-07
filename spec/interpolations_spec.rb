# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Interpolations" do
  let!(:task) { I18n::Tasks::BaseTask.new }

  context "with keys that are not plural forms" do
    let(:base_keys) do
      {"a" => "hello %{world}", "b" => "foo", "c" => {"d" => "hello %{name}"}, "e" => "ok", "f" => "%%{escaped}",
       "g" => "okay"}
    end
    let(:test_keys) do
      {"a" => "hello", "b" => "foo %{bar}", "c" => {"d" => "hola %{amigo}"}, "e" => "ok", "f" => "okay",
       "g" => "%%{ignored}"}
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

    it "#inconsistent_interpolation" do
      wrong = task.inconsistent_interpolations
      leaves = wrong.leaves.to_a

      expect(leaves.size).to eq 3
      expect(leaves[0].full_key).to eq "es.a"
      expect(leaves[1].full_key).to eq "es.b"
      expect(leaves[2].full_key).to eq "es.c.d"
    end
  end

  context "with plural forms" do
    around do |ex|
      TestCodebase.setup(
        "config/i18n-tasks.yml" => {
          base_locale: "en", locales: %w[ru he fr xx], ignore_inconsistent_interpolations: %w[ignored.few]
        }.to_yaml,
        "config/locales/en.yml" => {"en" => {
          "items" => {"zero" => "No items", "one" => "One item", "other" => "%{count} items"},
          "files" => {"one" => "%{count} file in %{folder}", "other" => "%{count} files in %{folder}"},
          "ignored" => {"one" => "%{count} thing", "other" => "%{count} things"}
        }}.to_yaml,
        "config/locales/ru.yml" => {"ru" => {
          # `one` is used for 1, 21, 31, ..., so it needs %{count}: "один элемент" is wrong
          "items" => {"0" => "Нет элементов", "one" => "один элемент", "few" => "%{count} элемента",
                      "many" => "%{count} элементов", "other" => "%{count} элемента"},
          # `hint` is not a plural form, so it is skipped and the forms are still checked
          "files" => {"one" => "%{count} файл в %{folder}", "few" => "несколько файлов в %{folder}",
                      "many" => "%{count} файлов", "other" => "%{count} файла в %{папка}", "hint" => "%{x}"},
          "ignored" => {"one" => "%{count} вещь", "few" => "несколько вещей", "many" => "%{count} вещей",
                        "other" => "%{count} вещи"}
        }}.to_yaml,
        "config/locales/he.yml" => {"he" => {
          # `one` is only used for 1, so it can spell the number out, but it must keep %{folder}.
          # rails-i18n never uses `two` in Hebrew, so it is checked like a form used for one count.
          "files" => {"one" => "קובץ אחד ב־%{folder}", "two" => "שני קבצים",
                      "other" => "%{count} קבצים ב־%{folder}"},
          "items" => {"one" => "פריט אחד", "two" => "שני פריטים ב־%{תיקייה}", "other" => "%{count} פריטים"}
        }}.to_yaml,
        "config/locales/fr.yml" => {"fr" => {
          # `one` is used for 0 and 1, unless there is a `zero` form
          "items" => {"zero" => "Aucun élément", "one" => "Un élément", "other" => "%{count} éléments"},
          "files" => {"one" => "Un fichier dans %{folder}", "other" => "%{count} fichiers dans %{folder}"}
        }}.to_yaml,
        "config/locales/xx.yml" => {"xx" => {
          # without a plural rule in rails-i18n, only `zero`, `one`, `two`, `0` and `1` can spell the number out
          "files" => {"one" => "a file in %{folder}", "two" => "both files in %{folder}",
                      "few" => "a few files in %{folder}", "other" => "%{count} files in %{folder}"}
        }}.to_yaml
      )

      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it "compares each form with the base forms and the counts it is used for" do
      keys = task.inconsistent_interpolations.leaves.map(&:full_key)

      expect(keys).to contain_exactly(
        "ru.items.one", "ru.files.few", "ru.files.many", "ru.files.other",
        "he.files.two", "he.items.two",
        "fr.files.one",
        "xx.files.few"
      )
    end

    it "counts the numbers each form is used for with the rails-i18n rule" do
      expect(task.plural_form_counts("ru", %w[one few many other])["one"]).to be > 1
      expect(task.plural_form_counts("he", %w[one two other])).not_to have_key("two")
      expect(task.plural_form_counts("he", %w[one two other])["one"]).to eq 1
      expect(task.plural_form_counts("fr", %w[one other])["one"]).to eq 2
      expect(task.plural_form_counts("fr", %w[zero one other])["one"]).to eq 1
      expect(task.plural_form_counts("xx", %w[one other])).to be_nil
    end
  end
end
