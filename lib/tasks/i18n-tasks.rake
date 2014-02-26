require 'i18n/tasks'
require 'i18n/tasks/commands'

cmd = I18n::Tasks::Commands.new

namespace :i18n do
  task :setup do
  end

  desc cmd.desc :missing
  task :missing, [:locales] => 'i18n:setup' do |t, args|
    cmd.missing locales: args[:locales]
  end

  namespace :missing do
    desc 'keys present in code but not existing in base locale data'
    task :missing_from_base => 'i18n:setup' do
      cmd.missing type: :missing_from_base
    end

    desc 'keys present but with value same as in base locale'
    task :eq_base, [:locales] => 'i18n:setup' do |t, args|
      cmd.missing type: :eq_base, locales: args[:locales]
    end

    desc 'keys that exist in base locale but are blank in passed locales'
    task :missing_from_locale, [:locales] => 'i18n:setup' do |t, args|
      cmd.missing type: :missing_from_locale, locales: args[:locales]
    end
  end

  desc cmd.desc :show_unused
  task :unused => 'i18n:setup' do
    cmd.unused
  end

  desc cmd.desc :remove_unused
  task :remove_unused, [:locales] => 'i18n:setup' do |t, args|
    cmd.remove_unused
  end

  desc cmd.desc :usages
  task :usages, [:filter] => 'i18n:setup' do |t, args|
    cmd.usages filter: args[:filter]
  end

  desc cmd.desc :normalize
  task :normalize, [:locales] => 'i18n:setup' do |t, args|
    cmd.normalize locales: args[:locales]
  end

  desc cmd.desc :add_missing
  task :add_missing, [:value] => 'i18n:setup' do |t, args|
    cmd.add_missing value: args[:value]
  end

  namespace :fill do
    desc 'add Google Translated values for untranslated keys to locales (default: all non-base)'
    task :google_translate, [:locales] => 'i18n:setup' do |t, args|
      cmd.fill from: :google_translate, locales: args[:locales]
    end

    desc 'copy base locale values for all untranslated keys to locales (default: all non-base)'
    task :base_value, [:locales] => 'i18n:setup' do |t, args|
      cmd.fill from: :base_value, locales: args[:locales]
    end

    desc 'add values for missing and untranslated keys to locales (default: all)'
    task :blanks, [:locales] => 'i18n:setup' do |t, args|
      cmd.fill from: :value, value: '', locales: args[:locales]
    end
  end

  desc cmd.desc(:config)
  task :tasks_config => 'i18n:setup' do
    cmd.config
  end

  desc cmd.desc :save_spreadsheet
  task :spreadsheet_report, [:path] => 'i18n:setup' do |t, args|
    cmd.save_spreadsheet path: args[:path]
  end
end

