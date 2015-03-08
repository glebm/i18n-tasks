module I18n::Tasks
  module Command
    module DSL
      module EnumOpt
        DEFAULT_ENUM_OPT_DESC = proc { |valid|
          I18n.t('i18n_tasks.cmd.enum_opt.desc', valid_text: valid)
        }

        # @param [Array] values valid argument values
        def enum_opt(name, *args, values, desc, error)
          enumerable_type! values
          desc ||= DEFAULT_ENUM_OPT_DESC
          cmd_opt name,
                  *args,
                  proc { desc.call(values * ', ') },
                  parser: Options::Enums::EnumParser.new(values, error),
                  default: values.first
        end

        DEFAULT_LIST_OPT_DESC = proc { |valid, default|
          I18n.t('i18n_tasks.cmd.enum_list_opt.desc', valid_text: valid, default_text: default)
        }

        # @param [Array] values valid argument values
        def enum_list_opt(name, *args, long, values, desc, error)
          desc ||= DEFAULT_LIST_OPT_DESC
          enumerable_type! values
          cmd_opt name,
                  *args,
                  "#{long} #{values * ','}",
                  proc { desc.call(values * ', ') },
                  parser: Options::Enums::EnumListParser.new(values, error),
                  default: 'all'
        end

        private
        def enumerable_type!(values)
          Enumerable === values or raise "Expected Array, got #{values.inspect}"
        end
      end
    end
  end
end
