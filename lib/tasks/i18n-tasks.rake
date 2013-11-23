require 'set'
require 'active_support/core_ext'

require 'i18n/tasks/missing'
require 'i18n/tasks/normalize'
require 'i18n/tasks/unused'
require 'i18n/tasks/prefill'
require 'i18n/tasks/translate'
require 'i18n/tasks/output/terminal'

namespace :i18n do
  desc 'show keys with missing translations'
  task :missing => :environment do
    if File.exists?('.i18nignore')
      STDERR.puts 'Looks like you are using .i18ignore. It is no longer used in favour of config/i18n-tasks.yml.'
      STDERR.puts 'See README.md https://github.com/glebm/i18n-tasks'
    end
    I18n::Tasks::Output::Terminal.new.missing I18n::Tasks::Missing.new.find_keys
  end

  desc 'show unused translations'
  task :unused => :environment do
    I18n::Tasks::Output::Terminal.new.unused I18n::Tasks::Unused.new.find_keys
  end

  desc 'normalize translation data: sort and move to the right files'
  task :normalize => :environment do
    I18n::Tasks::Normalize.new.perform
  end

  desc 'fill blank values with the help of Google Translate'
  task :translate, [:locales] => :environment do |t, args|
    task = I18n::Tasks::Translate.new
    args.with_defaults(locales: task.locales * ' ')
    task.perform args[:locales].strip.split(/\s+/)
  end

  desc 'prefill translations from base locale to others'
  task :prefill_with_base => :environment do
    I18n::Tasks::Prefill.new.perform
  end

  # todo prefill_with[Hello world]
end
