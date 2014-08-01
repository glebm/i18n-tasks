module I18n::Tasks
  module Command
    module Commands
      module Missing
        include Command::Collection

        enum_opt :missing_types, I18n::Tasks::MissingKeys.missing_keys_types
        cmd_opt :missing_types, enum_list_opt_attr(
            :t, :types=, enum_opt(:missing_types),
            proc { |valid, default| I18n.t('i18n_tasks.cmd.args.desc.missing_types', valid: valid, default: default) },
            proc { |invalid, valid| I18n.t('i18n_tasks.cmd.errors.invalid_missing_type', invalid: invalid * ', ', valid: valid * ', ', count: invalid.length) })

        cmd :missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.missing'),
            opt:  cmd_opts(:locales, :out_format, :missing_types)

        def missing(opt = {})
          print_forest i18n.missing_keys(opt), opt, :missing_keys
        end

        cmd :translate_missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.translate_missing'),
            opt:  [cmd_opt(:locales),
                   cmd_opt(:locale).merge(short: :f, long: :from=, desc: 'Locale to translate from (default: base)'),
                   cmd_opt(:out_format).except(:short)]

        def translate_missing(opt = {})
          from       = opt[:from]
          translated = (opt[:locales] - [from]).inject i18n.empty_forest do |result, locale|
            result.merge! i18n.google_translate_forest i18n.missing_tree(locale, from), from, locale
          end
          i18n.data.merge! translated
          log_stderr I18n.t('i18n_tasks.translate_missing.translated', count: translated.leaves.count)
          print_forest translated, opt
        end

        DEFAULT_ADD_MISSING_VALUE = '%{value_or_human_key}'

        cmd :add_missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.add_missing'),
            opt:  cmd_opts(:locales, :out_format) <<
                      cmd_opt(:value).merge(desc: "#{cmd_opt(:value)[:desc]}. #{I18n.t('i18n_tasks.cmd.args.default_text', value: DEFAULT_ADD_MISSING_VALUE)}")

        def add_missing(opt = {})
          forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || DEFAULT_ADD_MISSING_VALUE)
          i18n.data.merge! forest
          log_stderr I18n.t('i18n_tasks.add_missing.added', count: forest.leaves.count)
          print_forest forest, opt
        end
      end
    end
  end
end
