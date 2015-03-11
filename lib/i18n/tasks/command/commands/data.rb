module I18n::Tasks
  module Command
    module Commands
      module Data
        include Command::Collection

        arg :pattern_router,
            '-p',
            '--pattern_router',
            t('i18n_tasks.cmd.args.desc.pattern_router')

        cmd :normalize,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.normalize'),
            args: [:locales, :pattern_router]

        def normalize(opt = {})
          i18n.normalize_store! opt[:locales], opt[:pattern_router]
        end

        cmd :data,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.data'),
            args: [:locales, :out_format]

        def data(opt = {})
          print_forest i18n.data_forest(opt[:locales]), opt
        end

        cmd :data_merge,
            pos:  '[tree ...]',
            desc: t('i18n_tasks.cmd.desc.data_merge'),
            args: [:data_format, :nostdin]

        def data_merge(opt = {})
          forest = merge_forests_stdin_and_pos!(opt)
          merged = i18n.data.merge!(forest)
          print_forest merged, opt
        end

        cmd :data_write,
            pos:  '[tree]',
            desc: t('i18n_tasks.cmd.desc.data_write'),
            args: [:data_format, :nostdin]

        def data_write(opt = {})
          forest = forest_pos_or_stdin!(opt)
          i18n.data.write forest
          print_forest forest, opt
        end

        cmd :data_remove,
            pos:  '[tree]',
            desc: t('i18n_tasks.cmd.desc.data_remove'),
            args: [:data_format, :nostdin]

        def data_remove(opt = {})
          removed = i18n.data.remove_by_key!(forest_pos_or_stdin!(opt))
          log_stderr 'Removed:'
          print_forest removed, opt
        end
      end
    end
  end
end
