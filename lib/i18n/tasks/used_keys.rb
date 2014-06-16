# coding: utf-8
require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'

module I18n::Tasks::UsedKeys

  # find all keys in the source (relative keys are absolutized)
  # @option opts [false|true] :src_locations
  # @option opts [String] :key_filter
  # @return [Array<String>]
  def used_keys(opts = {})
    if opts[:key_filter]
      scanner.with_key_filter(opts[:key_filter]) do
        return used_keys(opts.except(:key_filter))
      end
    else
      if opts[:src_locations]
        used_keys_group scanner.keys_with_src_locations
      else
        @used_keys ||= used_keys_group scanner.keys
      end
    end
  end

  def used_keys_group(keys)
    ::I18n::Tasks::KeyGroup.new keys, type: :used, key_filter: scanner.key_filter
  end

  def scanner
    @scanner ||= begin
      search_config = (config[:search] || {}).with_indifferent_access
      class_name    = search_config[:scanner] || '::I18n::Tasks::Scanners::PatternWithScopeScanner'
      class_name.constantize.new search_config.merge(relative_roots: relative_roots)
    end
  end

  # whether the key is used in the source
  def used_key?(key)
    used_keys.include?(key)
  end

  # @return whether the key is potentially used in a code expression such as:
  #   t("category.#{category_key}")
  def used_in_expr?(key)
    !!(key =~ expr_key_re)
  end

  # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
  def expr_key_re
    @expr_key_re ||= compile_key_pattern "{#{used_keys.keys.select(&:expr?).map(&:key_match_pattern) * ','}}"
  end
end
