# coding: utf-8
module I18n::Tasks::Reports
  class Base
    include I18n::Tasks::Logging

    def initialize(task = I18n::Tasks::BaseTask.new)
      @task = task
    end

    attr_reader :task
    delegate :base_locale, :locales, to: :task

    protected

    def missing_type_info(type)
      ::I18n::Tasks::MissingKeys::MISSING_TYPES[type.to_s.sub(/\Amissing_/, '').to_sym]
    end

    def missing_title(forest)
      "Missing translations (#{forest.leaves.count || '∅'})"
    end

    def unused_title(key_values)
      "Unused keys (#{key_values.count || '∅'})"
    end

    def eq_base_title(key_values, locale = base_locale)
      "Same value as #{locale} (#{key_values.count || '∅'})"
    end

    def used_title(used_tree)
      leaves = used_tree.leaves.to_a
      filter = used_tree.first.root.data[:key_filter]
      used_n = leaves.map { |node| node.data[:source_occurrences].size }.reduce(:+).to_i
      "#{leaves.length} key#{'s' if leaves.size != 1}#{" matching '#{filter}'" if filter}#{" (#{used_n} usage#{'s' if used_n != 1})" if used_n > 0}"
    end

    # Sort keys by their attributes in order
    # @param [Hash] order e.g. {locale: :asc, type: :desc, key: :asc}
    def sort_by_attr!(objects, order = {locale: :asc, key: :asc})
      order_keys = order.keys
      objects.sort! { |a, b|
        by = order_keys.detect { |k| a[k] != b[k] }
        order[by] == :desc ? b[by] <=> a[by] : a[by] <=> b[by]
      }
      objects
    end

    def forest_to_attr(forest)
      forest.keys(root: false).map { |key, node|
        {key: key, value: node.value, type: node.data[:type], locale: node.root.key, data: node.data}
      }
    end
  end
end
