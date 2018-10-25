# frozen_string_literal: true

require 'set'
module I18n::Tasks
  module MissingKeys # rubocop:disable Metrics/ModuleLength
    MISSING_TYPES = %w[
      used
      diff
      plural
    ].freeze

    def self.missing_keys_types
      @missing_keys_types ||= MISSING_TYPES
    end

    def missing_keys_types
      MissingKeys.missing_keys_types
    end

    # @param types [:used, :diff, :plural] all if `nil`.
    # @return [Siblings]
    def missing_keys(locales: nil, types: nil, base_locale: nil)
      locales ||= self.locales
      types   ||= missing_keys_types
      base = base_locale || self.base_locale
      types.inject(empty_forest) do |f, type|
        f.merge! send(:"missing_#{type}_forest", locales, base)
      end
    end

    def eq_base_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      (locales - [base_locale]).inject(empty_forest) do |tree, locale|
        tree.merge! equal_values_tree(locale, base_locale)
      end
    end

    def missing_diff_forest(locales, base = base_locale)
      tree = empty_forest
      # present in base but not locale
      (locales - [base]).each do |locale|
        tree.merge! missing_diff_tree(locale, base)
      end
      if locales.include?(base)
        # present in locale but not base
        (self.locales - [base]).each do |locale|
          tree.merge! missing_diff_tree(base, locale)
        end
      end
      tree
    end

    def missing_used_forest(locales, _base = base_locale)
      locales.inject(empty_forest) do |forest, locale|
        forest.merge! missing_used_tree(locale)
      end
    end

    def missing_plural_forest(locales, _base = base_locale) # rubocop:disable Metrics/AbcSize
      locales.each_with_object(empty_forest) do |locale, tree|
        next unless I18n.exists?(:'i18n.plural.keys', locale)

        required_keys = Set.new(I18n.t(:'i18n.plural.keys', locale: locale, resolve: false))

        data[locale].leaves.map(&:parent).compact.uniq.each do |node|
          children     = node.children
          present_keys = Set.new(children.to_hash.keys.map(&:to_sym))
          next if !plural_forms?(children) || present_keys.superset?(required_keys)
          node.value    = children.to_hash
          node.children = nil
          node.data[:missing_keys] = (required_keys - present_keys).to_a
          tree.merge!(node.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
        end

        tree.set_root_key!(locale, type: :missing_plural)
      end
    end

    # keys present in compared_to, but not in locale
    def missing_diff_tree(locale, compared_to = base_locale)
      data[compared_to].select_keys do |key, _node|
        locale_key_missing? locale, depluralize_key(key, compared_to)
      end.set_root_key!(locale, type: :missing_diff).keys do |_key, node|
        # change path and locale to base
        data = { locale: locale, missing_diff_locale: node.data[:locale] }
        if node.data.key?(:path)
          data[:path] = LocalePathname.replace_locale(node.data[:path], node.data[:locale], locale)
        end
        node.data.update data
      end
    end

    # keys used in the code missing translations in locale
    def missing_used_tree(locale)
      used_tree(strict: true).select_keys do |key, _node|
        locale_key_missing?(locale, key)
      end.set_root_key!(locale, type: :missing_used)
    end

    def equal_values_tree(locale, compare_to = base_locale)
      base = data[compare_to].first.children
      data[locale].select_keys(root: false) do |key, node|
        other_node = base[key]
        other_node && !node.reference? && node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      end.set_root_key!(locale, type: :eq_base)
    end

    def locale_key_missing?(locale, key)
      !key_value?(key, locale) && !external_key?(key) && !ignore_key?(key, :missing)
    end

    # @param [::I18n::Tasks::Data::Tree::Siblings] forest
    # @yield [::I18n::Tasks::Data::Tree::Node]
    # @yieldreturn [Boolean] whether to collapse the node
    def collapse_same_key_in_locales!(forest)
      locales_and_node_by_key = {}
      to_remove               = []
      forest.each do |root|
        locale = root.key
        root.keys do |key, node|
          next unless yield node
          if locales_and_node_by_key.key?(key)
            locales_and_node_by_key[key][0] << locale
          else
            locales_and_node_by_key[key] = [[locale], node]
          end
          to_remove << node
        end
      end
      forest.remove_nodes_and_emptied_ancestors! to_remove
      locales_and_node_by_key.each_with_object({}) do |(key, (locales, node)), inv|
        (inv[locales.sort.join('+')] ||= []) << [key, node]
      end.map do |locales, keys_nodes|
        keys_nodes.each do |(key, node)|
          forest["#{locales}.#{key}"] = node
        end
      end
      forest
    end
  end
end
