module I18n::Tasks
  module Command
    module Options
      module Enums
        class EnumParser
          DEFAULT_ERROR = proc { |invalid, valid|
            I18n.t('i18n_tasks.cmd.enum_opt.invalid', invalid: invalid, valid: valid * ', ')
          }

          def initialize(valid, error_message = DEFAULT_ERROR)
            @valid         = valid.map(&:to_s)
            @error_message = error_message
          end

          def call(value, *)
            return @valid.first unless value.present?
            if @valid.include?(value)
              value
            else
              raise CommandError.new @error_message.call(value, @valid)
            end
          end
        end

        class EnumListParser
          include Options::Lists::Parsing
          DEFAULT_ERROR = proc { |invalid, valid|
            I18n.t('i18n_tasks.cmd.enum_list_opt.invalid', invalid: invalid * ', ', valid: valid * ', ')
          }

          def initialize(valid, error_message = DEFAULT_ERROR)
            @valid         = valid.map(&:to_s)
            @error_message = error_message
          end

          def call(values, *)
            return @valid if values == 'all'
            values  = explode_list_opt(values)
            invalid = values - @valid
            if invalid.empty?
              if values.empty?
                @valid
              else
                values
              end
            else
              raise CommandError.new @error_message.call(invalid, @valid)
            end
          end
        end
      end
    end
  end
end