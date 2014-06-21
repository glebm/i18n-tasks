# coding: utf-8
module I18n::Tasks
  module MissingKeys

    def missing_tree(locale, compared_to = base_locale)
      if locale == compared_to
        # keys used, but not present in locale
        used_missing_keys = used_tree.key_names(root: false).reject { |key|
          key_expression?(key) || key_value?(key, locale) || ignore_key?(key, :missing)
        }

        tree = Data::Tree::Siblings.from_key_names(used_missing_keys, parent_key: locale).leaves do |node|
          node.data[:type] = :missing_from_base
        end
        Data::Tree::Siblings.new nodes: [tree.parent]
      else
        # keys present in compared_to, but not in locale
        data[compared_to].select_keys { |key, node|
          !key_value?(key, locale) && !ignore_key?(key, :missing)
        }.leaves do |node|
          node.data[:type] = :missing_from_locale
        end.siblings { |root| root.key = locale }
      end
    end

    # @param [:missing_from_base, :missing_from_locale, :eq_base] type (default nil)
    # @return [KeyGroup]
    def missing_keys(opts = {})
      locales = Array(opts[:locales]).presence || self.locales
      types   = Array(opts[:type] || opts[:types].presence || missing_keys_types)

      types.map { |type|
        if type.to_s == 'missing_from_base'
          if locales.include?(base_locale)
            missing_tree(base_locale)
          end
        else
          non_base_locales(locales).map { |locale|
            if type.to_s == 'eq_base'
              eq_base_tree(locale)
            else
              collapse_plural_nodes! missing_tree(locale)
            end
          }.reduce(:merge!)
        end
      }.compact.reduce(:merge!)
    end

    def missing_keys_types
      @missing_keys_types ||= [:missing_from_base, :eq_base, :missing_from_locale]
    end

    def eq_base_tree(locale)
      tree = data[base_locale].first.children.intersect_keys(data[locale].first.children, root: false) { |key, node, other_node|
        node.value == other_node.value && !ignore_key?(key, :eq_base, locale)
      }.leaves { |node| node.data[:type] = :eq_base }
      tree.parent = Data::Tree::Node.new(key: locale, children: tree)
      Data::Tree::Siblings.new nodes: [tree.parent]
    end
  end
end
