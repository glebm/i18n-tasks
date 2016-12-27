# frozen_string_literal: true
module I18n::Tasks
  module Command
    module Commands
      module Tree
        include Command::Collection
        include I18n::Tasks::KeyPatternMatching

        cmd :tree_translate,
            pos:  '[tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_translate'),
            args: [:locale_to_translate_from, arg(:data_format).from(1)]

        def tree_translate(opts = {})
          forest = forest_pos_or_stdin!(opts)
          print_forest i18n.google_translate_forest(forest, opts[:from]), opts
        end

        cmd :tree_merge,
            pos:  '[[tree] [tree] ... (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_merge'),
            args: [:data_format, :nostdin]

        def tree_merge(opts = {})
          print_forest merge_forests_stdin_and_pos!(opts), opts
        end

        cmd :tree_filter,
            pos:  '[pattern] [tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_filter'),
            args: [:data_format, :pattern]

        def tree_filter(opts = {})
          pattern = arg_or_pos! :pattern, opts
          forest  = forest_pos_or_stdin! opts
          unless pattern.blank?
            pattern_re = i18n.compile_key_pattern(pattern)
            forest     = forest.select_keys { |full_key, _node| full_key =~ pattern_re }
          end
          print_forest forest, opts
        end

        cmd :tree_rename_key,
            pos:  'KEY_PATTERN NAME [tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_rename_key'),
            args: [['-k', '--key KEY_PATTERN', t('i18n_tasks.cmd.args.desc.key_pattern_to_rename')],
                   ['-n', '--name NAME', t('i18n_tasks.cmd.args.desc.new_key_name')],
                   :data_format]

        def tree_rename_key(opt = {})
          warn_deprecated 'Use tree-mv instead.'
          key    = arg_or_pos! :key, opt
          name   = arg_or_pos! :name, opt
          forest = forest_pos_or_stdin! opt
          fail CommandError, 'pass full key to rename (-k, --key)' if key.blank?
          fail CommandError, 'pass new name (-n, --name)' if name.blank?
          forest.rename_each_key!(key, name)
          print_forest forest, opt
        end

        cmd :tree_mv,
            pos: 'FROM_KEY_PATTERN TO_KEY_PATTERN [tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_mv_key'),
            args: [:data_format]
        def tree_mv(opt = {})
          fail CommandError, 'requires FROM_KEY_PATTERN and TO_KEY_PATTERN' if opt[:arguments].size < 2
          from_pattern = opt[:arguments].shift
          to_pattern = opt[:arguments].shift
          forest = forest_pos_or_stdin!(opt)
          forest.mv_key!(compile_key_pattern(from_pattern), to_pattern, root: false)
          print_forest forest, opt
        end

        cmd :tree_subtract,
            pos:  '[[tree] [tree] ... (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_subtract'),
            args: [:data_format, :nostdin]

        def tree_subtract(opt = {})
          forests = forests_stdin_and_pos! opt, 2
          forest  = forests.reduce(:subtract_by_key) || empty_forest
          print_forest forest, opt
        end

        cmd :tree_set_value,
            pos:  '[VALUE] [tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_set_value'),
            args: [:value, :data_format, :nostdin, :pattern]

        def tree_set_value(opt = {})
          value       = arg_or_pos! :value, opt
          forest      = forest_pos_or_stdin!(opt)
          key_pattern = opt[:pattern]
          fail CommandError, 'pass value (-v, --value)' if value.blank?
          forest.set_each_value!(value, key_pattern)
          print_forest forest, opt
        end

        cmd :tree_convert,
            pos:  '[tree (or stdin)]',
            desc: t('i18n_tasks.cmd.desc.tree_convert'),
            args: [arg(:data_format).dup.tap { |a| a[0..1] = ['-f', '--from FORMAT'] },
                   arg(:out_format).dup.tap { |a| a[0..1] = ['-t', '--to FORMAT'] }]

        def tree_convert(opt = {})
          forest = forest_pos_or_stdin! opt.merge(format: opt[:from])
          print_forest forest, opt.merge(format: opt[:to])
        end
      end
    end
  end
end
