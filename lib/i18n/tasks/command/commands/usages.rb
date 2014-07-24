module I18n::Tasks
  module Command
    module Commands
      module Usages
        include Command::Collection

        cmd_opt :strict, {
            short: :s,
            long:  :strict,
            desc:  I18n.t('i18n_tasks.cmd.args.desc.strict')
        }

        cmd :find,
            args: '[pattern]',
            desc: I18n.t('i18n_tasks.cmd.desc.find'),
            opt:  cmd_opts(:out_format, :pattern)

        def find(opt = {})
          opt_output_format! opt
          opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
          print_forest i18n.used_tree(key_filter: opt[:filter].presence, source_occurrences: true), opt, :used_keys
        end

        cmd :unused,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.unused'),
            opt:  cmd_opts(:locales, :out_format, :strict)

        def unused(opt = {})
          opt_locales! opt
          opt_output_format! opt
          print_forest i18n.unused_keys(opt), opt, :unused_keys
        end

        cmd :remove_unused,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.remove_unused'),
            opt:  cmd_opts(:locales, :out_format, :strict, :confirm)

        def remove_unused(opt = {})
          opt_locales! opt
          opt_output_format! opt
          unused_keys = i18n.unused_keys(opt)
          if unused_keys.present?
            terminal_report.unused_keys(unused_keys)
            confirm_remove_unused!(unused_keys, opt)
            removed = i18n.data.remove_by_key!(unused_keys)
            log_stderr I18n.t('i18n_tasks.remove_unused.removed', count: unused_keys.leaves.count)
            print_forest removed, opt
          else
            log_stderr bold green I18n.t('i18n_tasks.remove_unused.noop')
          end
        end

        private

        def confirm_remove_unused!(unused_keys, opt)
          return if ENV['CONFIRM'] || opt[:confirm]
          locales = bold(opt[:locales] * ', ')
          msg     = [
              red(I18n.t('i18n_tasks.remove_unused.confirm', count: unused_keys.leaves.count, locales: locales)),
              yellow(I18n.t('i18n_tasks.common.continue_q')),
              yellow('(yes/no)')
          ] * ' '
          exit 1 unless agree msg
        end
      end
    end
  end
end
