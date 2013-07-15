# coding: utf-8
require 'open3'
module I18n
  module Tasks
    module TaskHelpers
      # Run command and get only stdout output
      def run_command(*args)
        _in, out, _err = Open3.popen3(*args)
        out.gets nil
      end

      # compile prefix matching Regexp from the list of prefixes
      def compile_start_with_re(prefixes)
        /^(?:#{prefixes.map{|p| Regexp.escape(p) }.join('|')})/
      end

      # exclude @keys with prefixes matching @patterns
      def exclude_patterns(keys, patterns)
        pattern_re = compile_start_with_re patterns.select { |p| p.end_with?('.') }
        (keys - patterns).reject { |k| k =~ pattern_re }
      end
    end
  end
end
