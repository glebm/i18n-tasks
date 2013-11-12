require 'i18n/tasks/key_pattern_matching'

# e.g t("category.#{category_key}")
module I18n::Tasks
  module FuzzySourceKeys
    include KeyPatternMatching

    # dynamically generated keys in the source, e.g t("category.#{category_key}")
    def pattern_key?(key)
      @pattern_keys_re ||= compile_start_with_re(pattern_key_prefixes)
      key =~ @pattern_keys_re
    end

    # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
    def pattern_key_prefixes
      @pattern_keys_prefixes ||=
          find_source_keys.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }.map { |k| k.split(/\.?#/)[0].presence }.compact
    end
  end
end