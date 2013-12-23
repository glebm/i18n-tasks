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

  # Run given block for every relevant file, according to search_config
  # @return [Array] Results of block calls
  def traverse_files
    result = []
    Find.find(*search_config[:paths]) do |path|
      next if File.directory?(path)
      next if search_config[:include] and !search_config[:include].any? { |glob| File.fnmatch(glob, path) }
      next if search_config[:exclude].any? { |glob| File.fnmatch(glob, path) }
      result << yield(path)
    end
    result
  end

  # Extract i18n keys from file
  # @return [String] keys used in file (absolutized and unique)
  def extract_keys(path)
    keys = []
    File.open(path, 'rb') do |f|
      while (line = f.gets)
        line.scan(search_config[:pattern]) do |match|
          key = parse_key(match)
          key = absolutize_key(key, path) if key.start_with? '.'
          if key =~ /^[\w.\#{}]+$/
            keys << key
          end
        end
      end
    end
    keys
  end

  private
  # remove the leading colon and unwrap quotes from the key match
  def parse_key(match)
    key = match[0]
    key.slice!(0) if ':' == key[0]
    key = key[1..-2] if %w(' ").include?(key[0])
    key
  end
end
