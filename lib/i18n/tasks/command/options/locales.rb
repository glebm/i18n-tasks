module I18n::Tasks
  module Command
    module Options
      module Locales
        include Command::DSL

        module LocaleValidator
          VALID_LOCALE_RE = /\A\w[\w\-\.]*\z/i

          def validate!(locale)
            if VALID_LOCALE_RE !~ locale
              raise CommandError.new(I18n.t('i18n_tasks.cmd.errors.invalid_locale', invalid: locale))
            end
            locale
          end
        end

        module LocaleParser
          module_function
          extend LocaleValidator

          # @param [#base_locale, #locales] context
          def call(val, context)
            if val.blank? || val == 'base'
              context.base_locale
            else
              validate! val
            end
          end
        end

        module LocaleListParser
          module_function
          extend Lists::Parsing
          extend LocaleValidator

          # @param [#base_locale,#locales] context
          def call(vals, context)
            if vals == ['all'] || vals.blank?
              context.locales
            else
              explode_list_opt(vals).map { |v| v == 'base' ? context.base_locale : v }
            end.tap do |locales|
              locales.each { |locale| validate! locale }
            end
          end
        end

        cmd_opt :locales,
                '-l',
                '--locales en,es,ru',
                t('i18n_tasks.cmd.args.desc.locales_filter'),
                parser: LocaleListParser,
                default: 'all',
                consume_positional: true

        cmd_opt :locale,
                '-l',
                '--locale en',
                t('i18n_tasks.cmd.args.desc.locale'),
                parser:  LocaleParser,
                default: 'base'

        cmd_opt :locale_to_translate_from,
                '-f',
                '--from en',
                t('i18n_tasks.cmd.args.desc.locale_to_translate_from'),
                parser:  LocaleParser,
                default: 'base'
      end
    end
  end
end
