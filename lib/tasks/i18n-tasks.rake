require 'set'
require 'i18n/tasks/base_task'
require 'i18n/tasks/reports/terminal'
require 'active_support/core_ext/module/delegation'

namespace :i18n do
  desc 'show missing translations'
  task :missing => 'i18n:setup' do
    i18n_report.missing_translations
  end

  desc 'show unused translations'
  task :unused => 'i18n:setup' do
    i18n_report.unused_translations
  end

  desc 'normalize translation data: sort and move to the right files'
  task :normalize, [:locales] => 'i18n:setup' do |t, args|
    i18n_tasks.normalize_store! args[:locales]
  end

  desc 'add <key: placeholder || key.humanize> to the base locale'
  task :add_missing, [:placeholder] => 'i18n:setup' do |t, args|
    i18n_tasks.add_missing! base_locale, args[:placeholder]
  end

  desc 'fill translations with values'
  namespace :fill do

    desc 'add <key: ""> to each locale'
    task :blanks, [:locales] => 'i18n:setup' do |t, args|
      i18n_tasks.fill_with_blanks! i18n_parse_locales args[:locales]
    end

    desc 'add <key: Google Translated value> to each non-base locale, uses env GOOGLE_TRANSLATE_API_KEY'
    task :google_translate, [:locales] => 'i18n:setup' do |t, args|
      i18n_tasks.fill_with_google_translate! i18n_parse_locales args[:locales]
    end

    desc 'add <key: base value> to each non-base locale'
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
      @report ||= I18n::Tasks::Reports::Terminal.new
    end

    def i18n_parse_locales(arg = nil)
      arg.try(:strip).try(:split, /\s*\+\s*/).try(:compact)
    end
  end
  include ::I18n::Tasks::RakeHelpers
end

