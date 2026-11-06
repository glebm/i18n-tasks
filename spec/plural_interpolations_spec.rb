# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Interpolations in plural forms" do
  let!(:task) { I18n::Tasks::BaseTask.new }

  around do |ex|
    TestCodebase.setup(
      "config/i18n-tasks.yml" => {
        base_locale: "en", locales: %w[ru he], ignore_inconsistent_interpolations: %w[ignored.few]
      }.to_yaml,
      "config/locales/en.yml" => {"en" => {
        "items" => {"zero" => "No items", "one" => "One item", "other" => "%{count} items"},
        "files" => {"one" => "%{count} file in %{folder}", "other" => "%{count} files in %{folder}"},
        "ignored" => {"one" => "%{count} thing", "other" => "%{count} things"}
      }}.to_yaml,
      "config/locales/ru.yml" => {"ru" => {
        # `one` also covers 21, 31, ... in Russian, so it needs %{count} even though the English `one` omits it
        "items" => {"zero" => "Нет элементов", "one" => "%{count} элемент", "few" => "%{count} элемента",
                    "many" => "%{count} элементов", "other" => "%{count} элемента"},
        "files" => {"one" => "%{count} файл в %{folder}", "few" => "несколько файлов в %{folder}",
                    "many" => "%{count} файлов", "other" => "%{count} файла в %{папка}"},
        "ignored" => {"one" => "%{count} вещь", "few" => "несколько вещей", "many" => "%{count} вещей",
                      "other" => "%{count} вещи"}
      }}.to_yaml,
      "config/locales/he.yml" => {"he" => {
        # a dual spells the number out ("two files"), so a `two` form is only checked for unknown variables
        "files" => {"one" => "קובץ אחד ב־%{folder}", "two" => "שני קבצים", "other" => "%{count} קבצים ב־%{folder}"},
        "items" => {"one" => "פריט אחד", "two" => "שני פריטים ב־%{תיקייה}", "other" => "%{count} פריטים"}
      }}.to_yaml
    )

    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  it "compares each form with the same base form, or with other for forms the base does not have" do
    keys = task.inconsistent_interpolations.leaves.map(&:full_key)

    # ru: few dropped %{count}, many dropped %{folder}, other renamed %{folder}; items and ignored.few are fine.
    # he: one dropped %{count}, which the English `one` has; items.two uses an unknown variable; files.two is fine.
    expect(keys).to contain_exactly("ru.files.few", "ru.files.many", "ru.files.other", "he.files.one", "he.items.two")
  end
end
