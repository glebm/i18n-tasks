# coding: utf-8
require 'i18n/tasks/commands_base'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  class Commands < CommandsBase
    include Term::ANSIColor
    require 'highline/import'

    on_locale_opt = { as: Array, delimiter: /[+:,]/, default: 'all', argument: true, optional: false }
    OPT = {
        locale: proc {
          on '-l', :locales=,
             'Filter by locale(s), comma-separated list (en,fr) or all (default), or pass arguments without -l',
             on_locale_opt
        },
        format: proc {
          on '-f', :format=,
             "Output format: #{VALID_TREE_FORMATS * ', '}. Default: terminal-table.",
             {default: 'terminal-table', argument: true, optional: false}
        },
        strict: proc {
          on :s, :strict, %Q(Strict mode: do not match dynamic calls such as `t("category.\#{category.name}")`)
        }
    }
    desc 'show missing translations'
    opts do
      instance_exec &OPT[:locale]
      instance_exec &OPT[:format]
      on '-t', :types=, 'Filter by type (types: used, diff)', as: Array, delimiter: /[+:,]/
    end
    cmd :missing do |opt = {}|
      parse_locales! opt
      print_locale_tree i18n.missing_keys(opt), opt, :missing_keys
    end

    desc 'show unused translations'
    opts do
      instance_exec &OPT[:locale]
      instance_exec &OPT[:format]
      instance_exec &OPT[:strict]
    end
    cmd :unused do |opt = {}|
      parse_locales! opt
      print_locale_tree i18n.unused_keys(opt), opt, :unused_keys
    end

    desc 'show translations equal to base value'
    opts do
      instance_exec &OPT[:format]
    end
    cmd :eq_base do |opt = {}|
      parse_locales! opt
      print_locale_tree i18n.eq_base_keys(opt), opt, :eq_base_keys
    end

    desc 'show where the keys are used in the code'
    opts do
      on '-p', :pattern=, 'Show only keys matching pattern', argument: true, optional: false
      instance_exec &OPT[:format]
    end
    cmd :find do |opt = {}|
      opt[:filter] ||= opt.delete(:pattern) || opt[:arguments].try(:first)
      print_locale_tree i18n.used_tree(key_filter: opt[:filter].presence, source_locations: true), opt, :used_keys
    end

    desc 'show locale data'
    opts do
      instance_exec &OPT[:locale]
      instance_exec &OPT[:format]
    end
    cmd :data do |opt = {}|
      parse_locales! opt
      print_locale_tree i18n.data_forest(opt[:locales]), opt
    end

    desc 'translate missing keys with Google Translate'
    opts do
      on '-l', :locales=, 'Locales to translate (comma-separated, default: all)', on_locale_opt
      on '-f', :from=, 'Locale to translate from (default: base)', default: 'base', argument: true, optional: false
    end
    cmd :translate_missing do |opt = {}|
      opt[:from] = base_locale if opt[:from].blank? || opt[:from] == 'base'
      parse_locales! opt
      i18n.fill_missing_google_translate opt
    end

    desc 'add missing keys to the locales'
    opts do
      on '-l', :locales=, 'Locales to add keys into (comma-separated, default: all)', on_locale_opt
      on '-p', :placeholder=, 'Value for empty keys (default: base value or key.humanize)', argument: true, optional: false
    end
    cmd :add_missing do |opt = {}|
      parse_locales! opt
      opt[:value] ||= opt.delete(:placeholder) || proc { |key, locale|
        # default to base value or key.humanize
        locale != base_locale && t(key, base_locale) || SplitKey.split_key(key).last.to_s.humanize
      }

      v = opt[:value]
      if v.is_a?(String) && v.include?('%{base_value}')
        opt[:value] = proc { |key, locale, node|
          base_value = node.value || t(key, base_locale) || ''
          v % {base_value: base_value}
        }
      end

      i18n.fill_missing_value opt
    end

    desc 'normalize translation data: sort and move to the right files'
    opts do
      on '-l', :locales=, 'Locales to normalize (comma-separated, default: all)', on_locale_opt
      on '-p', :pattern_router, 'Use pattern router, regardless of config.', argument: false, optional: true
    end
    cmd :normalize do |opt = {}|
      parse_locales! opt
      i18n.normalize_store! opt[:locales], opt[:pattern_router]
    end

    desc 'remove unused keys'
    opts do
      on '-l', :locales=, 'Locales to remove unused keys from (comma-separated, default: all)', on_locale_opt
    end
    cmd :remove_unused do |opt = {}|
      parse_locales! opt
      unused_keys = i18n.unused_keys(opt)
      if unused_keys.present?
        terminal_report.unused_keys(unused_keys)
        unless ENV['CONFIRM']
          exit 1 unless agree(red "#{unused_keys.leaves.count} translations will be removed in #{bold opt[:locales] * ', '}#{red '.'} " + yellow('Continue? (yes/no)') + ' ')
        end
        i18n.remove_unused!(opt[:locales])
        $stderr.puts "Removed #{unused_keys.leaves.count} keys"
      else
        $stderr.puts bold green 'No unused keys to remove'
      end
    end

    desc 'display i18n-tasks configuration'
    cmd :config do
      cfg = i18n.config_for_inspect.to_yaml
      cfg.sub! /\A---\n/, ''
      cfg.gsub! /^([^\s-].+?:)/, Term::ANSIColor.cyan(Term::ANSIColor.bold('\1'))
      puts cfg
    end

    desc 'save missing and unused translations to an Excel file'
    opts do
      on :path=, 'Destination path', default: 'tmp/i18n-report.xlsx'
    end
    cmd :xlsx_report do |opt = {}|
      begin
        require 'axlsx'
      rescue LoadError
        message = %Q(For spreadsheet report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
        log_stderr Term::ANSIColor.red Term::ANSIColor.bold message
        exit 1
      end
      spreadsheet_report.save_report opt[:path]
    end

    desc 'REPL session within i18n-tasks context'
    cmd :irb do
      require 'i18n/tasks/console_context'
      ::I18n::Tasks::ConsoleContext.start
    end

    desc 'show path to the gem'
    cmd :gem_path do
      puts File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    end
  end
end
