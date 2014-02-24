require 'set'
require 'i18n/tasks'
require 'i18n/tasks/reports/terminal'
require 'active_support/core_ext/module/delegation'
require 'i18n/tasks/reports/spreadsheet'

namespace :i18n do
  require 'highline/import'

  task :setup do
  end

  desc 'show missing translations'
  task :missing, [:locales] => 'i18n:setup' do |t, args|
    i18n_report.missing_keys i18n_task.missing_keys(locales: i18n_parse_locales(args[:locales]))
  end

  namespace :missing do
    desc 'keys present in code but not existing in base locale data'
    task :missing_from_base => 'i18n:setup' do |t, args|
      i18n_report.missing_keys i18n_task.keys_missing_from_base
    end

    desc 'keys present but with value same as in base locale'
    task :eq_base, [:locales] => 'i18n:setup' do |t, args|
      i18n_report.missing_keys i18n_task.missing_keys(type: :eq_base, locales: i18n_parse_locales(args[:locales]))
    end

    desc 'keys that exist in base locale but are blank in passed locales'
    task :missing_from_locale, [:locales] => 'i18n:setup' do |t, args|
      i18n_report.missing_keys i18n_task.missing_keys(type: :missing_from_locale, locales: i18n_parse_locales(args[:locales]))
    end
  end

  desc 'show unused translations'
  task :unused => 'i18n:setup' do
    i18n_report.unused_keys
  end

  desc 'add placeholder for missing values to the base locale (default: key.humanize)'
  task :add_missing, [:placeholder] => 'i18n:setup' do |t, args|
    i18n_task.add_missing! base_locale, args[:placeholder]
  end

  desc 'remove unused keys'
  task :remove_unused, [:locales] => 'i18n:setup' do |t, args|
    locales     = i18n_parse_locales(args[:locales]) || i18n_task.locales
    unused_keys = i18n_task.unused_keys
    if unused_keys.present?
      i18n_report.unused_keys(unused_keys)
      unless ENV['CONFIRM']
        exit 1 unless agree(red "All these translations will be removed in #{bold locales * ', '}#{red '.'} " + yellow('Continue? (yes/no)') + ' ')
      end
      i18n_task.remove_unused!(locales)
    else
      STDERR.puts bold green 'No unused keys to remove'
    end
  end
  
  desc 'show usages of the keys in the codebase'
  task :usages, [:filter] => 'i18n:setup' do |t, args|
    filter = args[:filter] ? args[:filter].tr('+', ',') : nil
    i18n_report.used_keys(
        i18n_task.scanner.with_key_filter(filter) {
          i18n_task.used_keys(true)
        }
    )
  end

  desc 'normalize translation data: sort and move to the right files'
  task :normalize, [:locales] => 'i18n:setup' do |t, args|
    i18n_task.normalize_store! args[:locales]
  end

  desc 'save missing and unused translations to an Excel file'
  task :spreadsheet_report, [:path] => 'i18n:setup' do |t, args|
    begin
      require 'axlsx'
    rescue LoadError
      message = %Q(To use i18n:spreadsheet_report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
      STDERR.puts Term::ANSIColor.red Term::ANSIColor.bold message
      exit 1
    end
    args.with_defaults path: 'tmp/i18n-report.xlsx'
    i18n_spreadsheet_report.save_report(args[:path])
  end

  desc 'fill translations with values'
  namespace :fill do

    desc 'add "" values for missing and untranslated keys to locales (default: all)'
    task :blanks, [:locales] => 'i18n:setup' do |t, args|
      i18n_task.fill_with_blanks! i18n_parse_locales args[:locales]
    end

    desc 'add Google Translated values for untranslated keys to locales (default: all non-base)'
    task :google_translate, [:locales] => 'i18n:setup' do |t, args|
      i18n_task.fill_with_google_translate! i18n_parse_locales args[:locales]
    end

    desc 'copy base locale values for all untranslated keys to locales (default: all non-base)'
    task :base_value, [:locales] => 'i18n:setup' do |t, args|
      i18n_task.fill_with_base_values! i18n_parse_locales args[:locales]
    end
  end

  module ::I18n::Tasks::RakeHelpers
    include Term::ANSIColor

    delegate :base_locale, to: :i18n_task

    def i18n_task
      @i18n_task ||= I18n::Tasks::BaseTask.new
    end

    def i18n_report
      @i18n_report ||= I18n::Tasks::Reports::Terminal.new
    end

    def i18n_spreadsheet_report
      @i18n_spreadsheet_report ||= I18n::Tasks::Reports::Spreadsheet.new
    end

    def i18n_parse_locales(arg = nil)
      arg.try(:strip).try(:split, /\s*\+\s*/).try(:compact).try(:presence)
    end
  end
  include ::I18n::Tasks::RakeHelpers
end

