require 'i18n/tasks/commands_base'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < CommandsBase
    include Term::ANSIColor
    require 'highline/import'

    desc 'show missing translations'
    opts do
      on '-l', :locales=, 'Filter by locale', as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false
      on '-t', :types, 'Filter by type (types: missing_from_base, eq_base, missing_from_locale)', as: Array, delimiter: /[+:,]/, argument: true, optional: false
    end
    cmd :missing do |opt = {}|
      opt[:locales] = locales_opt(opt[:locales])
      terminal_report.missing_keys i18n_task.missing_keys(opt)
    end

    desc 'show unused translations'
    cmd :unused do
      terminal_report.unused_keys
    end

    desc 'translate missing keys with Google Translate'
    opts do
      on '-l', :locales, 'Only specified locales', as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false
      on '-f', :from, 'Locale to translate from (default: base)', default: 'base', argument: true, optional: false
    end
    cmd :translate_missing do |opt = {}|
      opt[:from] = base_locale if opt[:from].blank? || opt[:from] == 'base'
      opt[:locales] = locales_opt(opt[:locale] || opt[:locales])
      i18n_task.fill_missing_google_translate opt
    end

    desc 'add missing keys to the locales'
    opts do
      on '-p', :placeholder, 'Value for empty keys (default: base value or key.humanize)', argument: true, optional: false
      on '-l', :locales, 'Only for specified locales', as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false
    end
    cmd :add_missing do |opt = {}|
      opt[:locales] = locales_opt(opt[:locale] || opt[:locales])
      opt[:value] ||= opt.delete(:placeholder)
      opt[:value] ||= proc { |key, locale|
        # default to base value or key.humanize
        locale == base_locale && t(locale, base_locale) || key.split('.').last.to_s.humanize
      }
      i18n_task.fill_missing_value opt
    end

    desc 'show where the keys are used in the code'
    opts do
      on '-p', :pattern, 'Show only keys matching pattern', argument: true, optional: false
    end
    cmd :find do |opt = {}|
      opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
      filter = opt[:filter].is_a?(String) ? opt[:filter].tr('+', ',') : nil
      used_keys = i18n_task.scanner.with_key_filter(filter) {
        i18n_task.used_keys true
      }
      terminal_report.used_keys used_keys
    end

    desc 'normalize translation data: sort and move to the right files'
    opts do
      on '-l', :locales=, 'Only for specified locales', as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false
    end
    cmd :normalize do |opt = {}|
      i18n_task.normalize_store! locales_opt(opt[:locales])
    end

    desc 'remove unused keys'
    opts do
      on '-l', :locales=, 'Only for specified locales', as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false
    end
    cmd :remove_unused do |opt = {}|
      locales = locales_opt opt[:locales]
      unused_keys = i18n_task.unused_keys
      if unused_keys.present?
        terminal_report.unused_keys(unused_keys)
        unless ENV['CONFIRM']
          exit 1 unless agree(red "All these translations will be removed in #{bold locales * ', '}#{red '.'} " + yellow('Continue? (yes/no)') + ' ')
        end
        i18n_task.remove_unused!(locales)
        $stderr.puts "Removed #{unused_keys.size} keys"
      else
        $stderr.puts bold green 'No unused keys to remove'
      end
    end

    desc 'display i18n-tasks configuration'
    cmd :config do
      puts i18n_task.config_for_inspect.to_yaml.sub(/\A---\n/, '').gsub('!ruby/hash:ActiveSupport::HashWithIndifferentAccess', '')
    end

    desc 'save missing and unused translations to an Excel file'
    opts do
      on :path, 'Destination path', default: 'tmp/i18n-report.xlsx'
    end
    cmd :xlsx_report do |opt = {}|
      begin
        require 'axlsx'
      rescue LoadError
        message = %Q(For spreadsheet report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
        STDERR.puts Term::ANSIColor.red Term::ANSIColor.bold message
        exit 1
      end
      spreadsheet_report.save_report opt[:path]
    end

    protected

    def terminal_report
      @terminal_report ||= I18n::Tasks::Reports::Terminal.new(i18n_task)
    end

    def spreadsheet_report
      @spreadsheet_report ||= I18n::Tasks::Reports::Spreadsheet.new(i18n_task)
    end
  end
end
