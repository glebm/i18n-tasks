require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      def perform
        grep_out = run_command 'grep', '-horI', %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, 'app/'
        used_keys = grep_out.split("\n").map { |r| r.match(/['"](.*?)['"]/)[1] }.uniq.to_set
        pattern_prefixes = used_keys.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }.map { |k| k.split(/\.?#/)[0] }
        traverse base[base_locale] do |key, value|
          if !used_keys.include?(key) && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
            puts "#{key}: #{value}"
          end
        end
      end
    end
  end
end
