require 'set'
require 'i18n/tasks/base_task'
require 'i18n/tasks/reports/terminal'
require 'active_support/core_ext/module/delegation'
require 'i18n/tasks/reports/spreadsheet'

namespace :i18n do
  desc 'show missing translations'
  task :missing => 'i18n:setup' do
    i18n_report.missing_translations
  end

  desc 'show unused translations'
  task :unused => 'i18n:setup' do
    i18n_report.unused_translations
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

  desc 'normalize translation data: sort and move to the right files'
  task :normalize, [:locales] => 'i18n:setup' do |t, args|
    i18n_tasks.normalize_store! args[:locales]
  end

  desc 'add placeholder for missing values to the base locale (default: key.humanize)'
  task :add_missing, [:placeholder] => 'i18n:setup' do |t, args|
    i18n_tasks.add_missing! base_locale, args[:placeholder]
  end

  desc 'fill translations with values'
  namespace :fill do

    desc 'add "" values for missing and untranslated keys to locales (default: all)'
    task :blanks, [:locales] => 'i18n:setup' do |t, args|
      i18n_tasks.fill_with_blanks! i18n_parse_locales args[:locales]
    end

    desc 'add Google Translated values for untranslated keys to locales (default: all non-base)'
    task :google_translate, [:locales] => 'i18n:setup' do |t, args|
      i18n_tasks.fill_with_google_translate! i18n_parse_locales args[:locales]
    end

    desc 'copy base locale values for all untranslated keys to locales (default: all non-base)'
    task :base_value, [:locales] => 'i18n:setup' do |t, args|
      i18n_tasks.fill_with_base_values! i18n_parse_locales args[:locales]
    end
  end

  task 'i18n:setup' => :environment do
    if File.exists?('.i18nignore')
      I18n::Tasks.warn_deprecated "Looks like you are using .i18ignore. It is no longer used in favour of config/i18n-tasks.yml.\n
See README.md https://github.com/glebm/i18n-tasks"
    end
  end

  module ::I18n::Tasks::RakeHelpers
    include Term::ANSIColor

    delegate :base_locale, to: :i18n_tasks

    def i18n_tasks
      @i18n_tasks ||= I18n::Tasks::BaseTask.new
    end

    def i18n_report
      @i18n_report ||= I18n::Tasks::Reports::Terminal.new
    end

    def i18n_spreadsheet_report
      @i18n_spreadsheet_report ||= I18n::Tasks::Reports::Spreadsheet.new
    end

    def i18n_parse_locales(arg = nil)
      arg.try(:strip).try(:split, /\s*\+\s*/).try(:compact)
    end
  end
  include ::I18n::Tasks::RakeHelpers
end

