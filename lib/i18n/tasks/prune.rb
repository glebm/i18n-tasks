# frozen_string_literal: true

module I18n::Tasks::Prune
  def prunable_keys(base_locale:, locales:)
    diff_forest = empty_forest
    locales.each do |locale|
      # Based on the docs, missing_diff_tree only returns keys that are in the second argument but not in the first
      locale_forest =
        missing_diff_tree(base_locale, locale).tap do |locale_forest|
          locale_forest.mv_key!(compile_key_pattern(base_locale), locale, root: true)
        end

      diff_forest.merge!(locale_forest)
    end

    diff_forest
  end
end
