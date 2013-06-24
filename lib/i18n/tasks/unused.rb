require 'i18n/tasks/task_helpers'
module I18n
  module Tasks
    module Unused
      include TaskHelpers
      extend self
      def perform
        _in, out, _err = Open3.popen3 'grep', '-horI', %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, 'app/'
        used_keys = out.gets(nil).split("\n").map { |r| r.match(/['"](.*?)['"]/)[1] }.uniq.to_set
        pattern_prefixes = used_keys.select { |key| key =~ /\#{.*?}/ || key.ends_with?('.') }.map { |key| key.split(/\.?#/)[0] }
        traverse base[base_locale] do |key, value|
          if !used_keys.include?(key) && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
            puts "#{key}: #{value}"
          end
        end
      end
    end
  end
end
