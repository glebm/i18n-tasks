require 'i18n/tasks/command/options/enum_opt'
require 'i18n/tasks/command/options/list_opt'

module I18n::Tasks
  module Command
    module Options
      module Common
        extend Command::DSL
        include Options::EnumOpt
        include Options::ListOpt

        VALID_LOCALE_RE = /\A\w[\w\-\.]*\z/i

        cmd_opt :nostdin, {
            short: :S,
            long:  :nostdin,
            desc:  proc { I18n.t('i18n_tasks.cmd.args.desc.nostdin') },
            conf:  {default: false}
        }

        cmd_opt :confirm, {
            short: :y,
            long:  :confirm,
            desc:  proc { I18n.t('i18n_tasks.cmd.args.desc.confirm') },
            conf:  {default: false}
        }

        cmd_opt :pattern, {
            short: :p,
            long:  :pattern=,
            desc:  proc { I18n.t('i18n_tasks.cmd.args.desc.key_pattern') },
            conf:  {argument: true, optional: false}
        }

        cmd_opt :value, {
            short: :v,
            long:  :value=,
            desc:  proc { I18n.t('i18n_tasks.cmd.args.desc.value') },
            conf:  {argument: true, optional: false}
        }

        def opt_or_arg!(key, opt)
          opt[key] ||= opt[:arguments].try(:shift)
        end
      end
    end
  end
end
