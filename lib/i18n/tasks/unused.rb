# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      DESC = 'Unused i18n keys'
      def perform
        unused = find_unused
        STDERR.puts bold cyan("#{DESC} (#{unused.length})")
        unused.each do |(key, value)|
          puts " #{magenta(key).ljust(60)}\t#{cyan value}"
        end
      end

      def find_unused
        used_keys = find_source_keys.to_set
        r = []
        ignore_re = ignore_pattern(:unused)
        pattern_re = compile_start_with_re find_source_pattern_prefixes
        traverse base[base_locale] do |key, value|
          unless used_keys.include?(key) || key =~ pattern_re || key =~ ignore_re
            r << [key, value]
          end
        end
        r
      end
    end
  end
end
