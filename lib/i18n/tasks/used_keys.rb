require 'find'
require 'i18n/tasks/scanners/pattern_scanner'

module I18n::Tasks::UsedKeys
  # find all keys in the source (relative keys are absolutized)
  # @return [Array<String>]
  def used_keys(with_usages = false)
    if with_usages
      I18n::Tasks::KeyGroup.new(scanner.keys_with_usages, type: :used, key_filter: scanner.key_filter)
    else
      @used_keys ||= I18n::Tasks::KeyGroup.new(scanner.keys, type: :used, key_filter: scanner.key_filter)
    end
  end

  def scanner
    @scanner ||= begin
      search_config = (config[:search] || {}).with_indifferent_access
      class_name    = search_config[:scanner] || '::I18n::Tasks::Scanners::PatternScanner'
      class_name.constantize.new search_config.merge(relative_roots: relative_roots)
    end
  end

  # whether the key is used in the source
  def used_key?(key)
    used_keys.include?(key)
  end

  # dynamically generated keys in the source, e.g t("category.#{category_key}")
  def pattern_key?(key)
    @pattern_keys_re ||= compile_start_with_re(pattern_key_prefixes)
    !!(key =~ @pattern_keys_re)
  end

  # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
  def pattern_key_prefixes
    @pattern_keys_prefixes ||=
        used_keys.key_names.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }.map { |k| k.split(/\.?#/)[0].presence }.compact
  end
end
