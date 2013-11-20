require 'open3'
module I18n::Tasks::SourceKeys
  # find all keys in the source (relative keys are returned in absolutized)
  # @return [Array<String>]
  def find_source_keys
    @source_keys ||= begin
      if (grep_out = run_grep)
        grep_out.split("\n").map { |r|
          key = r.match(/['"](.*?)['"]/)[1]
          if key.start_with? '.'
            absolutize_key key, r.split(':')[0]
          else
            key
          end
        }.uniq.reject { |k| k !~ /^[\w.\#{}]+$/ }
      else
        []
      end
    end
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
      end
    end
  end

  # Run grep searching for source keys and return grep output
  # @return [String] output of the grep command
  def run_grep
    args = ['grep', '-HoRI']
    [:include, :exclude].each do |opt|
      next unless (val = grep_config[opt]).present?
      args += Array(val).map { |v| "--#{opt}=#{v}" }
    end
    args += [%q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, *grep_config[:paths]]
    args.compact!
    run_command *args
  end


  # Run command and get only stdout output
  # @return [String] output
  # @raise [RuntimeError] if grep returns with exit code other than 0
  def run_command(*args)
    o, e, s = Open3.capture3(*args)
    raise "#{args[0]} failed with status #{s.exitstatus} (stderr: #{e})" unless s.success?
    o
  end
end