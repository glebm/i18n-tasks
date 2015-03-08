require 'i18n/tasks/command/options/lists'
require 'i18n/tasks/command/options/enums'

module I18n::Tasks
  module Command
    module Options
      module Common
        include Command::DSL
        include Options::Enums

        cmd_opt :nostdin,
                '-S',
                '--nostdin',
                t('i18n_tasks.cmd.args.desc.nostdin')

        cmd_opt :confirm,
                '-y',
                '--confirm',
                desc: t('i18n_tasks.cmd.args.desc.confirm')

        cmd_opt :pattern,
                '-p',
                '--pattern PATTERN',
                t('i18n_tasks.cmd.args.desc.key_pattern')

        cmd_opt :value,
                '-v',
                '--value VALUE',
                t('i18n_tasks.cmd.args.desc.value')

        def opt_or_arg!(key, opt)
          opt[key] ||= opt[:arguments].try(:shift)
        end
      end
    end
  end
end
