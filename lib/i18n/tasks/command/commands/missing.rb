require 'i18n/tasks/command/collection'

module I18n::Tasks
  module Command
    module Commands
      module Missing
        include Command::Collection

        missing_types = I18n::Tasks::MissingKeys.missing_keys_types
        arg :missing_types,
            '-t',
            "--types #{missing_types * ','}",
            Array,
            t('i18n_tasks.cmd.args.desc.missing_types', valid: missing_types * ', '),
            parser: OptionParsers::Enum::ListParser.new(
                missing_types,
                proc { |invalid, valid| I18n.t('i18n_tasks.cmd.errors.invalid_missing_type',
                                               invalid: invalid * ', ', valid: valid * ', ', count: invalid.length) })

        cmd :missing,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.missing'),
            args: [:locales, :out_format, :missing_types]

        def missing(opt = {})
          forest = i18n.missing_keys(opt)
          print_forest forest, opt, :missing_keys
          :exit_1 unless forest.empty?
        end

        cmd :translate_missing,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.translate_missing'),
            args: [:locales, :locale_to_translate_from, arg(:out_format).from(1)]

        def translate_missing(opt = {})
          missing    = i18n.missing_diff_forest opt[:locales], opt[:from]
          translated = i18n.google_translate_forest missing, opt[:from]
          i18n.data.merge! translated
          log_stderr t('i18n_tasks.translate_missing.translated', count: translated.leaves.count)
          print_forest translated, opt
        end

        cmd :add_missing,
            pos:  '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.add_missing'),
            args: [:locales, :out_format, arg(:value) + [{default: '%{value_or_human_key}'}]]

        def add_missing(opt = {})
          added   = i18n.empty_forest
          locales = (opt[:locales] || i18n.locales)
          if locales[0] == i18n.base_locale
            # Merge base locale first, as this may affect the value for the other locales
            forest = i18n.missing_keys({locales: [locales[0]]}.update(opt.slice(:types, :base_locale))).
                set_each_value!(opt[:value])
            i18n.data.merge! forest
            added.merge! forest
            locales = locales[1..-1]
          end
          forest = i18n.missing_keys({locales: locales}.update(opt.slice(:types, :base_locale))).
              set_each_value!(opt[:value])
          i18n.data.merge! forest
          added.merge! forest
          log_stderr t('i18n_tasks.add_missing.added', count: added.leaves.count)
          print_forest added, opt
        end
      end
    end
  end
end
