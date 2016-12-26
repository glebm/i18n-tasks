# frozen_string_literal: true
module I18n::Tasks
  module Command
    module Commands
      module Usages
        include Command::Collection

        arg :strict,
            '--[no-]strict',
            t('i18n_tasks.cmd.args.desc.strict')

        cmd :find,
            pos:  '[pattern]',
            desc: t('i18n_tasks.cmd.desc.find'),
            args: [:out_format, :pattern, :strict]

        def find(opt = {})
          opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
          result = i18n.used_tree(strict: opt[:strict], key_filter: opt[:filter].presence, include_raw_references: true)
          print_forest result, opt, :used_keys
        end

        cmd :unused,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.unused'),
            args: [:locales, :out_format, :strict]

        def unused(opt = {})
          forest = i18n.unused_keys(opt.slice(:locales, :strict))
          print_forest forest, opt, :unused_keys
          :exit_1 unless forest.empty?
        end

        cmd :remove_unused,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.remove_unused'),
            args: [:locales, :out_format, :strict, :confirm]

        def remove_unused(opt = {})
          unused_keys = i18n.unused_keys(opt.slice(:locales, :strict))
          if unused_keys.present?
            terminal_report.unused_keys(unused_keys)
            confirm_remove_unused!(unused_keys, opt)
            removed = i18n.data.remove_by_key!(unused_keys)
            log_stderr t('i18n_tasks.remove_unused.removed', count: unused_keys.leaves.count)
            print_forest removed, opt
          else
            log_stderr bold green t('i18n_tasks.remove_unused.noop')
          end
        end

        private

        def confirm_remove_unused!(unused_keys, opt)
          return if ENV['CONFIRM'] || opt[:confirm]
          locales = bold(unused_keys.flat_map { |root| root.key.split('+') }.sort.uniq * ', ')
          msg     = [
            red(t('i18n_tasks.remove_unused.confirm', count: unused_keys.leaves.count, locales: locales)),
            yellow(t('i18n_tasks.common.continue_q')),
            yellow('(yes/no)')
          ].join(' ')
          exit 1 unless agree msg
        end
      end
    end
  end
end
