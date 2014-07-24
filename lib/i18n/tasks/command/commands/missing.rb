module I18n::Tasks
  module Command
    module Commands
      module Missing
        include Command::Collection

        cmd_opt :missing_types, {
            short: :t,
            long:  :types=,
            desc:  I18n.t('i18n_tasks.cmd.args.desc.missing_types', valid: I18n::Tasks::MissingKeys.missing_keys_types * ', '),
            conf:  {as: Array, delimiter: /\s*[+:,]\s*/}
        }

        DEFAULT_ADD_MISSING_VALUE = '%{value_or_human_key}'

        cmd :missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.missing'),
            opt:  cmd_opts(:locales, :out_format, :missing_types)

        def missing(opt = {})
          opt_locales!(opt)
          opt_output_format!(opt)
          opt_missing_types!(opt)
          print_forest i18n.missing_keys(opt), opt, :missing_keys
        end

        cmd :translate_missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.translate_missing'),
            opt:  [cmd_opt(:locales),
                   cmd_opt(:locale).merge(short: :f, long: :from=, desc: 'Locale to translate from (default: base)'),
                   cmd_opt(:out_format).except(:short)]

        def translate_missing(opt = {})
          opt_locales! opt
          opt_output_format! opt
          from       = opt_locale! opt, :from
          translated = (opt[:locales] - [from]).inject i18n.empty_forest do |result, locale|
            result.merge! i18n.google_translate_forest i18n.missing_tree(locale, from), from, locale
          end
          i18n.data.merge! translated
          log_stderr I18n.t('i18n_tasks.translate_missing.translated', count: translated.leaves.count)
          print_forest translated, opt
        end

        cmd :add_missing,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.add_missing'),
            opt:  cmd_opts(:locales, :out_format) <<
                      cmd_opt(:value).merge(desc: "#{cmd_opt(:value)[:desc]}. #{I18n.t('i18n_tasks.cmd.args.default_text', value: DEFAULT_ADD_MISSING_VALUE)}")

        def add_missing(opt = {})
          opt_locales! opt
          opt_output_format! opt
          forest = i18n.missing_keys(opt).set_each_value!(opt[:value] || DEFAULT_ADD_MISSING_VALUE)
          i18n.data.merge! forest
          log_stderr I18n.t('i18n_tasks.add_missing.added', count: forest.leaves.count)
          print_forest forest, opt
        end

        private

        def opt_missing_types!(opt)
          parse_enum_list_opt(opt[:types], I18n::Tasks::MissingKeys.missing_keys_types) do |invalid, valid|
            I18n.t('i18n_tasks.cmd.errors.invalid_missing_type',
                   invalid: invalid * ', ', valid: valid * ', ', count: invalid.length)
          end
        end
      end
    end
  end
end
