module I18n::Tasks
  module Command
    module Options
      module Lists
        module Parsing
          def explode_list_opt(list_opt, delim = /\s*[,]\s*/)
            Array(list_opt).compact.map { |v| v.strip.split(delim).compact.presence }.flatten.map(&:presence).compact
          end
        end
      end
    end
  end
end
