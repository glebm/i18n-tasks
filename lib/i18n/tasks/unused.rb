# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      DESC = 'Unused i18n keys'
      def perform
        unused = find_unused
        STDERR.puts bold cyan("= #{DESC} (#{unused.length}) =")
        unused.each do |(key, value)|
          puts " #{magenta(key).ljust(60)}\t#{cyan value}"
        end
      end

      def find_unused
        used_keys = find_source_keys
        pattern_prefixes = find_source_pattern_prefixes
        r = []
        traverse base[base_locale] do |key, value|
          r << [key, value] if !used_keys.include?(key) && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
        end
        r
      end
    end
  end
end
