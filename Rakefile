require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :irb do
  # $: << File.expand_path('lib', __FILE__)
  require 'i18n/tasks'
  require 'i18n/tasks/commands'
  ::I18n::Tasks::Commands.new.irb
end
