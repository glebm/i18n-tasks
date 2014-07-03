# coding: utf-8
require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'

module I18n::Tasks
  module UsedKeys

    # find all keys in the source (relative keys are absolutized)
    # @option opts [String] :key_filter
    # @return [Array<String>]
    def used_tree(opts = {})
      return scanner.with_key_filter(opts[:key_filter]) { used_tree(opts.except(:key_filter)) } if opts[:key_filter]
      key_attrs = scanner.keys
      Data::Tree::Node.new(
          key: 'used',
          data: {key_filter: scanner.key_filter},
          children: Data::Tree::Siblings.from_key_attr(key_attrs)
      ).to_siblings
    end

    def scanner
      @scanner ||= begin
        search_config = (config[:search] || {}).with_indifferent_access
        class_name    = search_config[:scanner] || '::I18n::Tasks::Scanners::PatternWithScopeScanner'
        class_name.constantize.new search_config.merge(relative_roots: relative_roots)
      end
    end

    def used_key_names
      @used_key_names ||= used_tree.key_names
    end

    # whether the key is used in the source
    def used_key?(key)
      used_key_names.include?(key)
    end

    # @return whether the key is potentially used in a code expression such as:
    #   t("category.#{category_key}")
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
    def expr_key_re
      @expr_key_re ||= begin
        patterns = used_key_names.select { |k| key_expression?(k) }.map { |k| key_match_pattern(k) }
        compile_key_pattern "{#{patterns * ','}}"
      end
    end
  end
end
