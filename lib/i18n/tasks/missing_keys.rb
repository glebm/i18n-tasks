# coding: utf-8
module I18n::Tasks
  module MissingKeys
    def missing_keys_types
      @missing_keys_types ||= [:missing_from_base, :eq_base, :missing_from_locale]
    end

    # @param [:missing_from_base, :missing_from_locale, :eq_base] type (default nil)
    # @return [Siblings]
    def missing_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      types   = Array(opts[:type] || opts[:types].presence || missing_keys_types)

      types.map { |type|
        case type.to_s
          when 'missing_from_base'
            missing_tree(base_locale) if locales.include?(base_locale)
          when 'missing_from_locale'
            non_base_locales(locales).map { |locale| missing_tree(locale) }.reduce(:merge!)
          when 'eq_base'
            non_base_locales(locales).map { |locale| eq_base_tree(locale) }.reduce(:merge!)
        end
      }.compact.reduce(:merge!)
    end

    def missing_tree(locale, compared_to = base_locale)
      if locale == compared_to
        # keys used, but not present in locale
        set_locale_tree_type used_tree.select_keys { |key, node|
          !(key_expression?(key) || key_value?(key, locale) || ignore_key?(key, :missing))
        }, locale, :missing_from_base
      else
        # keys present in compared_to, but not in locale
        collapse_plural_nodes! set_locale_tree_type data[compared_to].select_keys { |key, node|
          !key_value?(key, locale) && !ignore_key?(key, :missing)
        }, locale, :missing_from_locale
      end
    end

    def eq_base_tree(locale, compare_to = base_locale)
      base = data[compare_to].first.children
      set_locale_tree_type data[locale].select_keys(root: false) { |key, node|
        other_node = base[key]
        other_node && node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      }, locale, :eq_base
    end

    def set_locale_tree_type(tree, locale, type)
      tree.siblings { |root|
        root.key = locale
      }.leaves { |node|
        node.data[:type] = type
      }
    end
  end
end
