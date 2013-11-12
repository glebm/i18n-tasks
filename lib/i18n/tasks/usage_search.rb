require 'open3'
module I18n::Tasks::UsageSearch
  # grep config, also from config/i18n-tasks.yml
  # @return [Hash{String => String,Hash,Array}]
  def grep_config
    @grep_config ||= (config[:grep] || {}).with_indifferent_access.tap do |conf|
      conf[:paths] = ['app/'] if conf[:paths].blank?
    end
  end

  # whether the key is used in the source
  def used_key?(key)
    @used_keys ||= find_source_keys.to_set
    @used_keys.include?(key)
  end

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

  protected

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