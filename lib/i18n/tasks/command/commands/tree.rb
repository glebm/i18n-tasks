module I18n::Tasks
  module Command
    module Commands
      module Tree
        include Command::Collection

        cmd :tree_merge,
            args: '[tree ...]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_merge') },
            opt:  cmd_opts(:data_format, :nostdin)

        def tree_merge(opts = {})
          print_forest opt_forests_merged_stdin_args!(opts), opts
        end

        cmd :tree_filter,
            args: '[pattern] [tree]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_filter') },
            opt:  cmd_opts(:data_format, :pattern)

        def tree_filter(opt = {})
          pattern = opt_or_arg! :pattern, opt
          forest  = opt_forest_arg_or_stdin!(opt)
          unless pattern.blank?
            pattern_re = i18n.compile_key_pattern(pattern)
            forest     = forest.select_keys { |full_key, _node| full_key =~ pattern_re }
          end
          print_forest forest, opt
        end

        cmd :tree_rename_key,
            args: '<key> <name> [tree]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_rename_key') },
            opt:  [
                      cmd_opt(:pattern).merge(short: :k, long: :key=, desc: proc {
                        I18n.t('i18n_tasks.cmd.args.desc.key_pattern_to_rename') }),
                      cmd_opt(:pattern).merge(short: :n, long: :name=, desc: proc {
                        I18n.t('i18n_tasks.cmd.args.desc.new_key_name') })
                  ] + cmd_opts(:data_format)

        def tree_rename_key(opt = {})
          key    = opt_or_arg! :key, opt
          name   = opt_or_arg! :name, opt
          forest = opt_forest_arg_or_stdin! opt
          raise CommandError.new('pass full key to rename (-k, --key)') if key.blank?
          raise CommandError.new('pass new name (-n, --name)') if name.blank?
          forest.rename_each_key!(key, name)
          print_forest forest, opt
        end

        cmd :tree_subtract,
            args: '[tree A] [tree B ...]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_subtract') },
            opt:  cmd_opts(:data_format, :nostdin)

        def tree_subtract(opt = {})
          forests = opt_forests_stdin_args! opt, 2
          forest  = forests.reduce(:subtract_by_key) || empty_forest
          print_forest forest, opt
        end

        cmd :tree_set_value,
            args: '[value] [tree]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_set_value') },
            opt:  cmd_opts(:value, :data_format, :nostdin, :pattern)

        def tree_set_value(opt = {})
          value       = opt_or_arg! :value, opt
          forest      = opt_forest_arg_or_stdin!(opt)
          key_pattern = opt[:pattern]
          raise CommandError.new('pass value (-v, --value)') if value.blank?
          forest.set_each_value!(value, key_pattern)
          print_forest forest, opt
        end

        cmd :tree_convert,
            args: '<tree>',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.tree_convert') },
            opt:  [cmd_opt(:data_format).merge(short: :f, long: :from=),
                   cmd_opt(:out_format).merge(short: :t, long: :to=)]

        def tree_convert(opt = {})
          forest = opt_forest_arg_or_stdin! opt.merge(format: opt[:from])
          print_forest forest, opt.merge(format: opt[:to])
        end
      end
    end
  end
end
