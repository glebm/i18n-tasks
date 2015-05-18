# coding: utf-8
require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'

module I18n::Tasks
  module UsedKeys

    # find all keys in the source (relative keys are absolutized)
    # @option opts [String] :key_filter
    # @option opts [Boolean] :strict if true dynamic keys are excluded (e.g. `t("category.#{category.key}")`)
    # @return [Array<String>]
    def used_tree(opts = {})
      return scanner.with_key_filter(opts[:key_filter]) { used_tree(opts.except(:key_filter)) } if opts[:key_filter]
      Data::Tree::Node.new(
          key: 'used',
          data: {key_filter: scanner.key_filter},
          children: Data::Tree::Siblings.from_key_attr(scanner.keys(opts.slice(:strict)))
      ).to_siblings
    end

    def scanner
      @scanner ||= begin
        search_config = (config[:search] || {}).with_indifferent_access
        class_name    = search_config[:scanner] || '::I18n::Tasks::Scanners::PatternWithScopeScanner'
        ActiveSupport::Inflector.constantize(class_name).new search_config
      end
    end

    def used_key_names(strict = false)
      if strict
        @used_key_names ||= used_tree(strict: true).key_names
      else
        @used_key_names ||= used_tree.key_names
      end
    end

    # whether the key is used in the source
    def used_key?(key, strict = false)
      used_key_names(strict).include?(key)
    end

    # @return whether the key is potentially used in a code expression such as:
    #   t("category.#{category_key}")
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
    def expr_key_re
      @expr_key_re ||= begin
        patterns = used_key_names.select { |k| key_expression?(k) }.map { |k|
          pattern = key_match_pattern(k)
          # disallow patterns with no keys
          next if pattern =~ /\A(:\.)*:\z/
          pattern
        }.compact
        compile_key_pattern "{#{patterns * ','}}"
      end
    end
  end
end
