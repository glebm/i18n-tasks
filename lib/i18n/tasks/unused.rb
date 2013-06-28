require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Unused < BaseTask
      def perform
        used_keys = find_source_keys
        pattern_prefixes = find_source_pattern_prefixes
        traverse base[base_locale] do |key, value|
          if !used_keys.include?(key) && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
            puts "#{yellow 'unused'.ljust(10)}#{magenta(key).ljust(60)}\t#{cyan value}"
          end
        end
      end
    end
  end
end
