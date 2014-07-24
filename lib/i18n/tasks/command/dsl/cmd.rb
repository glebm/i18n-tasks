module I18n::Tasks
  module Command
    module DSL
      module Cmd
        def cmd(name, args = nil)
          if args
            dsl(:cmds)[name] = args
          else
            dsl(:cmds)[name]
          end
        end

        def cmds
          dsl(:cmds)
        end
      end
    end
  end
end
