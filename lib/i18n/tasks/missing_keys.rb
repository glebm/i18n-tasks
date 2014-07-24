# coding: utf-8
module I18n::Tasks
  module MissingKeys

    MISSING_TYPES = {
        used: {glyph: '✗', summary: 'used in code but missing from base locale'},
        diff: {glyph: '∅', summary: 'translated in one locale but not in the other'}
    }

    def self.missing_keys_types
      @missing_keys_types ||= MISSING_TYPES.keys
    end

    def missing_keys_types
      MissingKeys.missing_keys_types
    end

    # @param [:missing_used, :missing_diff] types (default nil)
    # @return [Siblings]
    def missing_keys(opts = {})
      locales = opts[:locales].presence || self.locales
      types   = opts[:types].presence || missing_keys_types
      base    = opts[:base_locale] || base_locale
      types.inject(empty_forest) do |f, type|
        f.merge! send(:"missing_#{type}_forest", locales, base)
      end
    end

    def eq_base_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      (locales - [base_locale]).inject(empty_forest) { |tree, locale|
        tree.merge! equal_values_tree(locale, base_locale)
      }
    end

    def missing_diff_forest(locales, base = base_locale)
      tree = empty_forest
      # present in base but not locale
      (locales - [base]).each { |locale|
        tree.merge! missing_diff_tree(locale, base)
      }
      if locales.include?(base)
        # present in locale but not base
        (self.locales - [base]).each { |locale|
          tree.merge! missing_diff_tree(base, locale)
        }
      end
      tree
    end

    def missing_used_forest(locales, base = base_locale)
      if locales.include?(base)
        missing_used_tree(base)
      else
        empty_forest
      end
    end

    def missing_tree(locale, compared_to)
      if locale == compared_to
        missing_used_tree locale
      else
        missing_diff_tree locale, compared_to
      end
    end

    # keys present in compared_to, but not in locale
    def missing_diff_tree(locale, compared_to = base_locale)
      data[compared_to].select_keys { |key, _node|
        locale_key_missing? locale, depluralize_key(key, locale)
      }.set_root_key!(locale, type: :missing_diff).keys { |_key, node|
        if node.data.key?(:path)
          # change path and locale to base
          node.data.update path: LocalePathname.replace_locale(node.data[:path], node.data[:locale], locale), locale: locale
        end
      }
    end

    # keys used in the code missing translations in locale
    def missing_used_tree(locale)
      used_tree(strict: true).select_keys { |key, _node|
        locale_key_missing?(locale, key)
      }.set_root_key!(locale, type: :missing_used)
    end

    def equal_values_tree(locale, compare_to = base_locale)
      base = data[compare_to].first.children
      data[locale].select_keys(root: false) { |key, node|
        other_node = base[key]
        other_node && node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      }.set_root_key!(locale, type: :eq_base)
    end

    def locale_key_missing?(locale, key)
      !key_value?(key, locale) && !ignore_key?(key, :missing)
    end
  end
end
