# coding: utf-8
require 'open3'

module I18n
  module Tasks
    module TaskHelpers
      # Run command and get only stdout output
      def run_command(*args)
        o, e, s = Open3.capture3(*args)
        raise "#{args[0]} failed with status #{s.exitstatus} (stderr: #{e})" unless s.success?
        o
      end

      # compile prefix matching Regexp from the list of prefixes
      def compile_start_with_re(prefixes)
        if prefixes.blank?
          /\Z\A/ # match nothing
        else
          /^(?:#{prefixes.map { |p| Regexp.escape(p) }.join('|')})/
        end
      end

      # exclude @keys with prefixes matching @patterns
      def exclude_patterns(keys, patterns)
        pattern_re = compile_start_with_re patterns.select { |p| p.end_with?('.') }
        (keys - patterns).reject { |k| k =~ pattern_re }
      end

      # type: missing, eq_base, unused
      def ignore_pattern(type, locale = nil)
        ((@ignore_patterns ||= HashWithIndifferentAccess.new)[type] ||= {})[locale] = begin
          global      = config[:ignore] || []
          type_ignore = config["ignore_#{type}"] || []
          if type_ignore.is_a?(Array)
            compile_start_with_re global + type_ignore
          elsif type_ignore.is_a?(Hash)
            p = global + (type_ignore[:all] || [])
            type_ignore.each { |key, value| p += (value || []) if key.to_s =~ /\b#{locale}\b/ } if locale
            compile_start_with_re p
          end
        end
      end

      # default configuration for grep, may be overridden with config/i18n-tasks.yml
      def grep_config
        @grep_config ||= (config[:grep] || {}).with_indifferent_access.tap do |conf|
          conf[:paths] = ['app/'] if conf[:paths].blank?
        end
      end

      def config
        I18n::Tasks.config
      end
    end
  end
end
