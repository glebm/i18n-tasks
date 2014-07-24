module I18n::Tasks
  module Command
    module DSL
      module EnumOpt
        def enum_opt(name, list = nil)
          if list
            dsl(:enum_valid)[name] = list
          else
            dsl(:enum_valid)[name]
          end
        end

        DEFAULT_ENUM_OPT_DESC = proc { |valid, default|
          I18n.t('i18n_tasks.cmd.enum_opt.desc.default', valid_text: valid, default_text: default)
        }

        def enum_opt_attr(short, long, valid, &desc)
          desc ||= DEFAULT_ENUM_OPT_DESC
          {short: short, long: long.to_sym,
           desc:  desc.call(valid * ', ', I18n.t('i18n_tasks.cmd.args.default_text', value: valid.first)),
           conf:  {default: valid.first, argument: true, optional: false}}
        end
      end
    end
  end
end
