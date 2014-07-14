# coding: utf-8
module I18n::Tasks
  module MissingKeys
    def missing_keys_types
      @missing_keys_types ||= [:missing_used, :missing_diff]
    end

    # @param [:missing_used, :missing_diff] type (default nil)
    # @return [Siblings]
    def missing_keys(opts = {})
      locales           = Array(opts[:locales]).presence || self.locales
      tree              = Data::Tree::Siblings.new
      types = Array(opts[:types]).presence || missing_keys_types

      (locales - [base_locale]).each { | locale|
        tree.merge! missing_diff_tree(locale, base_locale)
        tree.merge! missing_diff_tree(base_locale, locale) if locales.include?(base_locale)
      } if types.include?(:missing_diff)

      if locales.include?(base_locale) && types.include?(:missing_used)
        tree.merge! missing_used_tree(base_locale)
      end
      tree
    end

    def eq_base_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      (locales - [base_locale]).inject(Data::Tree::Siblings.new) { |tree, locale|
        tree.merge! equal_values_tree(locale, base_locale)
      }
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
        locale_key_missing?(locale, key)
      }.set_root_key(locale, type: :missing_diff).tap { |t| collapse_plural_nodes!(t) }
    end

    # keys used in the code missing translations in locale
    def missing_used_tree(locale)
      used_tree.select_keys { |key, _node|
        !key_expression?(key) && locale_key_missing?(locale, key)
      }.set_root_key(locale, type: :missing_used)
    end

    def equal_values_tree(locale, compare_to = base_locale)
      base = data[compare_to].first.children
      data[locale].select_keys(root: false) { |key, node|
        other_node = base[key]
        other_node && node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      }.set_root_key(locale, type: :eq_base)
    end

    def locale_key_missing?(locale, key)
      !key_value?(key, locale) && !ignore_key?(key, :missing)
    end
  end
end
