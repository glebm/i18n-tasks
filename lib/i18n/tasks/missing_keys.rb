# coding: utf-8
module I18n::Tasks
  module MissingKeys
    def missing_keys_types
      @missing_keys_types ||= [:used, :diff]
    end

    # @param [:missing_used, :missing_diff] type (default nil)
    # @return [Siblings]
    def missing_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      types   = (Array(opts[:types]).presence || missing_keys_types).map(&:to_s)
      validate_missing_types! types
      base    = opts[:base_locale] || base_locale
      tree    = Data::Tree::Siblings.new

      types.each do |type|
        tree.merge! send(:"missing_#{type}_forest", locales, base)
      end
      tree
    end

    def eq_base_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      (locales - [base_locale]).inject(Data::Tree::Siblings.new) { |tree, locale|
        tree.merge! equal_values_tree(locale, base_locale)
      }
    end

    def missing_diff_forest(locales, base = base_locale)
      tree = Data::Tree::Siblings.new
      # present in base but not locale
      (locales - [base]).each { |locale|
        tree.merge! missing_diff_tree(locale, base)
      }
      if locales.include?(base)
        # present in locale but not base
        (self.locales - [base]).each { |locale|
          tree.merge! missing_diff_tree(base, locale).set_root_key(base)
        }
      end
      tree
    end

    def missing_used_forest(locales, base = base_locale)
      if locales.include?(base)
        missing_used_tree(base)
      else
        Data::Tree::Siblings.new
      end
    end

    def missing_tree(locale, compared_to, collapse_plural = true)
      if locale == compared_to
        missing_used_tree locale
      else
        missing_diff_tree locale, compared_to, collapse_plural
      end
    end

    # keys present in compared_to, but not in locale
    def missing_diff_tree(locale, compared_to = base_locale, collapse_plural = true)
      data[compared_to].select_keys { |key, _node|
        locale_key_missing?(locale, key)
      }.set_root_key(locale, type: :missing_diff).tap { |t| collapse_plural_nodes!(t) if collapse_plural }
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

    private

    def validate_missing_types!(types)
      valid_types = missing_keys_types.map(&:to_s)
      types = types.map(&:to_s)
      invalid_types = types - valid_types
      if invalid_types.present?
        raise CommandError.new("Unknown types: #{invalid_types * ', '}. Valid types are: #{valid_types * ', '}.")
      end
      true
    end
  end
end
