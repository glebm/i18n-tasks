require 'set'
require 'active_support/core_ext'

require 'i18n/tasks/missing'
require 'i18n/tasks/prefill'
require 'i18n/tasks/unused'

namespace :i18n do
  desc 'add keys from base locale to others'
  task :prefill => :environment do
    I18n::Tasks::Prefill.new.perform
  end

  desc 'show keys with translation values identical to base'
  task :missing => :environment do
    I18n::Tasks::Missing.new.perform
  end

  desc 'find potentially unused translations'
  task :unused => :environment do
    I18n::Tasks::Unused.new.perform
  end
end
