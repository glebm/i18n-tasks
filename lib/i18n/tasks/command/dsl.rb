require 'i18n/tasks/command/dsl/cmd'
require 'i18n/tasks/command/dsl/cmd_opt'
require 'i18n/tasks/command/dsl/enum_opt'

module I18n::Tasks
  module Command
    module DSL
      def self.included(base)
        base.module_eval do
          @dsl = HashWithIndifferentAccess.new { |h, k|
            h[k] = HashWithIndifferentAccess.new
          }
          extend ClassMethods
        end
      end

      def t(*args)
        I18n.t(*args)
      end

      module ClassMethods
        include DSL::Cmd
        include DSL::CmdOpt
        include DSL::EnumOpt

        def dsl(key)
          @dsl[key]
        end

        # late-bound I18n.t for module bodies
        def t(*args)
          proc { I18n.t(*args) }
        end

        # if class is a module, merge DSL definitions when it is included
        def included(base)
          base.instance_variable_get(:@dsl).deep_merge!(@dsl)
        end
      end
    end
  end
end
