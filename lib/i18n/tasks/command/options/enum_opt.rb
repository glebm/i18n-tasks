module I18n::Tasks
  module Command
    module Options
      module EnumOpt
        DEFAULT_ENUM_OPT_ERROR = proc { |bad, good|
          I18n.t('i18n_tasks.cmd.enum_opt.invalid_one', invalid: bad, valid: good * ', ')
        }

        def parse_enum_opt(value, valid, &error_msg)
          valid = enum_opt(valid) if Symbol === valid
          return valid.first unless value.present?
          if enum_opt_valid?(valid, value)
            value
          else
            error_msg ||= DEFAULT_ENUM_OPT_ERROR
            raise CommandError.new error_msg.call(value, valid)
          end
        end

        def enum_opt_valid?(valid, value)
          valid = enum_opt(valid) if Symbol === valid
          valid.include?(value)
        end

        DEFAULT_ENUM_LIST_ERROR = proc { |bad, good|
          I18n.t('i18n_tasks.cmd.enum_opt.invalid_list', invalid: bad * ', ', valid: good * ', ')
        }

        def parse_enum_list_opt(values, valid, &error_msg)
          values  = explode_list_opt(values)
          invalid = values - valid.map(&:to_s)
          if invalid.empty?
            values
          else
            error_msg ||= DEFAULT_ENUM_LIST_ERROR
            raise CommandError.new error_msg.call(invalid, valid)
          end
        end

        def enum_opt(*args)
          self.class.enum_opt(*args)
        end
      end
    end
  end
end
