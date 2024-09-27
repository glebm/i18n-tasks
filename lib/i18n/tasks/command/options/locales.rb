# frozen_string_literal: true

require 'i18n/tasks/command/option_parsers/locale'
require 'i18n/tasks/command/option_parsers/enum'

module I18n::Tasks
  module Command
    module Options
      module Locales
        include Command::DSL

        arg :locales,
            '-l',
            '--locales en,es,ru',
            Array,
            t('i18n_tasks.cmd.args.desc.locales_filter'),
            parser: OptionParsers::Locale::ListParser,
            default: 'all',
            consume_positional: true

        arg :locale,
            '-l',
            '--locale en',
            t('i18n_tasks.cmd.args.desc.locale'),
            parser: OptionParsers::Locale::Parser,
            default: 'base'

        arg :locale_to_translate_from,
            '-f',
            '--from en',
            t('i18n_tasks.cmd.args.desc.locale_to_translate_from'),
            parser: OptionParsers::Locale::Parser,
            default: 'base'

        TRANSLATION_BACKENDS = %w[google deepl yandex openai watsonx].freeze
        arg :translation_backend,
            '-b',
            '--backend BACKEND',
            t('i18n_tasks.cmd.args.desc.translation_backend'),
            parser:
              OptionParsers::Enum::Parser.new(
                TRANSLATION_BACKENDS,
                proc do |value, valid|
                  if value.present?
                    I18n.t('i18n_tasks.cmd.errors.invalid_backend', invalid: value&.strip, valid: valid * ', ')
                  end
                end,
                allow_blank: true
              )
      end
    end
  end
end
