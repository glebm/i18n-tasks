require 'open3'
require 'find'

module I18n::Tasks::SourceKeys
  # find all keys in the source (relative keys are returned in absolutized)
  # @return [Array<String>]
  def find_source_keys
    @source_keys ||= traverse_files do |path|
      extract_keys(path)
    end.flatten.uniq
  end

  # whether the key is used in the source
  def used_key?(key)
    @used_keys ||= find_source_keys.to_set
    @used_keys.include?(key)
  end

  # dynamically generated keys in the source, e.g t("category.#{category_key}")
  def pattern_key?(key)
    @pattern_keys_re ||= compile_start_with_re(pattern_key_prefixes)
    !!(key =~ @pattern_keys_re)
  end

  # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
  def pattern_key_prefixes
    @pattern_keys_prefixes ||=
        find_source_keys.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }.map { |k| k.split(/\.?#/)[0].presence }.compact
  end

  protected

  # grep config, also from config/i18n-tasks.yml
  # @return [Hash{String => String,Hash,Array}]
  def grep_config
    @grep_config ||= begin
      if config.key?(:grep)
        config[:search] ||= config.delete(:grep)
        warn_deprecated 'please rename "grep" key to "search" in config/i18n-tasks.yml'
      end
      search_config = (config[:search] || {}).with_indifferent_access
      search_config.tap do |conf|
        conf[:paths] = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude])
      end
    end
  end

  # Run given block for every relevant file, according to grep_config
  # @return [Array] Results of block calls
  def traverse_files
    result = []
    Find.find(*grep_config[:paths]) do |path|
      next if File.directory?(path)
      next if grep_config[:include] and !grep_config[:include].any? { |glob| File.fnmatch(glob, path) }
      next if grep_config[:exclude].any? { |glob| File.fnmatch(glob, path) }
      result << yield(path)
    end
    result
  end

  # Extract i18n keys from file
  # @return [String] list of unique, absolut keys
  def extract_keys(path)
    keys = []
    File.open(path, 'rb') do |f|
      while (line = f.gets)
        line.scan(/\bt[( ]\s*(.)((?<=").+?(?=")|(?<=').+?(?=')|(?<=:)\w+\b)/) do |t, key|
          if key.start_with? '.'
            key = absolutize_key(key, path)
          elsif t == ':'
            key = absolutize_key(".#{key}", path)
          end
          keys << key
        end
      end
    end
    keys.select { |k| k =~ /^[\w.\#{}]+$/ }
  end
end
