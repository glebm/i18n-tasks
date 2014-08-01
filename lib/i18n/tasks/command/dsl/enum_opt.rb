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
          I18n.t('i18n_tasks.cmd.enum_opt.desc', valid_text: valid, default_text: default)
        }

        def enum_opt_attr(short, long, valid, desc, error_msg)
          desc ||= DEFAULT_ENUM_OPT_DESC
          desc_proc = proc { desc.call(valid * ', ', I18n.t('i18n_tasks.cmd.args.default_text', value: valid.first)) }
          {short: short, long: long, desc: desc_proc,
           conf:  {default: valid.first, argument: true, optional: false},
           parse: enum_parse_proc(:parse_enum_opt, long, valid, &error_msg)}
        end

        DEFAULT_LIST_OPT_DESC = proc { |valid, default|
          I18n.t('i18n_tasks.cmd.enum_list_opt.desc', valid_text: valid, default_text: default)
        }

        def enum_list_opt_attr(short, long, valid, desc, error_msg)
          desc ||= DEFAULT_LIST_OPT_DESC
          desc_proc = proc { desc.call(valid * ', ', I18n.t('i18n_tasks.cmd.args.default_all')) }
          {short: short, long: long, desc: desc_proc,
           conf:  {as: Array, delimiter: /\s*[+:,]\s*/},
           parse: enum_parse_proc(:parse_enum_list_opt, long, valid, &error_msg)}
        end

        def enum_parse_proc(method, key, valid, &error)
          key = key.to_s.sub(/=\z/, '').to_sym
          proc { |opt|
            opt[key] = send(method, opt[key], valid, &error)
          }
        end
      end
    end
  end
end
