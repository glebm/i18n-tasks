module I18n::Tasks
  module Command
    module Commands
      module Data
        include Command::Collection

        cmd_opt :pattern_router, {
            short: :p,
            long:  :pattern_router,
            desc:  I18n.t('i18n_tasks.cmd.args.desc.pattern_router'),
            conf:  {argument: false, optional: true}
        }

        cmd :normalize,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.normalize'),
            opt:  cmd_opts(:locales, :pattern_router)

        def normalize(opt = {})
          opt_locales! opt
          i18n.normalize_store! opt[:locales], opt[:pattern_router]
        end

        cmd :data,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.data'),
            opt:  cmd_opts(:locales, :out_format)

        def data(opt = {})
          opt_locales! opt
          opt_output_format! opt
          print_forest i18n.data_forest(opt[:locales]), opt
        end

        cmd :data_merge,
            args: '[tree ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.data_merge'),
            opt:  cmd_opts(:data_format, :nostdin)

        def data_merge(opt = {})
          opt_data_format! opt
          forest = opt_forests_merged_stdin_args!(opt)
          merged = i18n.data.merge!(forest)
          print_forest merged, opt
        end

        cmd :data_write,
            args: '[tree]',
            desc: I18n.t('i18n_tasks.cmd.desc.data_write'),
            opt:  cmd_opts(:data_format, :nostdin)

        def data_write(opt = {})
          opt_data_format! opt
          forest = opt_forest_arg_or_stdin!(opt)
          i18n.data.write forest
          print_forest forest, opt
        end

        cmd :data_remove,
            args: '[tree]',
            desc: I18n.t('i18n_tasks.cmd.desc.data_remove'),
            opt:  cmd_opts(:data_format, :nostdin)

        def data_remove(opt = {})
          opt_data_format! opt
          removed = i18n.data.remove_by_key!(opt_forest_arg_or_stdin!(opt))
          log_stderr 'Removed:'
          print_forest removed, opt
        end
      end
    end
  end
end
