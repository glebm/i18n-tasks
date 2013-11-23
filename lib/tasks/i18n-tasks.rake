require 'set'
require 'i18n/tasks/base_task'
require 'i18n/tasks/output/terminal'

namespace :i18n do
  desc 'show missing translations'
  task :missing => 'i18n:setup' do
    term_output.missing i18n_tasks.untranslated_keys
  end

  desc 'show unused translations'
  task :unused => 'i18n:setup' do
    term_output.unused i18n_tasks.unused_keys
  end

  desc 'normalize translation data: sort and move to the right files'
  task :normalize => 'i18n:setup' do
    i18n_tasks.normalize_store!
  end

  desc 'fill translations with values'
  namespace :fill do

    desc 'add <key: placeholder || key.humanize> to the base locale'
    task :add_missing, [:placeholder] => 'i18n:setup' do |t, args|
      normalize_store!
      i18n_tasks.fill_blanks!(locale: i18n_tasks.base_locale) { |keys|
        keys.map { |key|
          args[:placeholder] || key.split('.').last.to_s.humanize
        }
      }
    end

    desc 'add <key: ""> to each locale'
    task :with_blanks, [:locales] => 'i18n:setup' do |t, args|
      normalize_store!
      [base_locale, *locales_or_all(args)].uniq.each do |locale|
        i18n_tasks.fill_blanks!(locale: locale) { |keys| keys.map { "" } }
      end
    end

    desc 'add <key: Google Translated value> to each non-base locale, uses env GOOGLE_TRANSLATE_API_KEY'
    task :with_google, [:locales] => 'i18n:setup' do |t, args|
      normalize_store!
      (locales_or_all(args) - [base_locale]).each do |locale|
        i18n_tasks.fill_blanks!(locale: locale) { |keys|
          i18n_tasks.google_translate keys.map { |k| t(k) }, to: locale, from: base_locale
        }
      end
    end

    desc 'add <key: base value> to each non-base locale'
    task :with_base, [:locales] => 'i18n:setup' do |t, args|
      normalize_store!
      (locales_or_all(args) - [base_locale]).each do |locale|
        i18n_tasks.fill_blanks!(locale: locale) { |keys| keys.map { |k| t(k) } }
      end
    end
  end

  task 'i18n:setup' => :environment do
    if File.exists?('.i18nignore')
      STDERR.puts 'Looks like you are using .i18ignore. It is no longer used in favour of config/i18n-tasks.yml.'
      STDERR.puts 'See README.md https://github.com/glebm/i18n-tasks'
    end
  end

  module I18n::Tasks::RakeHelpers
    extend ActiveSupport::Concern

    included do
      delegate :t, :locales, :base_locale, :normalize_store!, to: :i18n_tasks

      def i18n_tasks
        @i18n_tasks ||= I18n::Tasks::BaseTask.new
      end

      def term_output
        @term_output ||= I18n::Tasks::Output::Terminal.new
      end

      def locales_or_all(args)
        args.with_defaults(locales: i18n_tasks.locales * '+')
        args[:locales].strip.split(/\s*\+\s*/)
      end
    end
  end

  include I18n::Tasks::RakeHelpers
  include Term::ANSIColor
end
