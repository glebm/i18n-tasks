module I18n::Tasks
  module Command
    module DSL
      module CmdOpt
        def cmd_opts(*args)
          dsl(:cmd_opts).values_at(*args)
        end

        def cmd_opt(arg, *opts)
          if opts.present?
            dsl(:cmd_opts)[arg] = opts
          else
            dsl(:cmd_opts)[arg]
          end
        end
      end
    end
  end
end
