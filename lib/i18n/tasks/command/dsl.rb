require 'i18n/tasks/command/dsl/cmd'
require 'i18n/tasks/command/dsl/cmd_opt'
require 'i18n/tasks/command/dsl/enum_opt'

module I18n::Tasks
  module Command
    module DSL
      include DSL::Cmd
      include DSL::CmdOpt
      include DSL::EnumOpt

      def self.extended(base)
        base.instance_variable_set :@dsl, HashWithIndifferentAccess.new { |h, k|
          h[k] = HashWithIndifferentAccess.new
        }
      end

      def included(base)
        base.instance_variable_get(:@dsl).deep_merge!(@dsl)
      end

      def dsl(key)
        @dsl[key]
      end
    end
  end
end
