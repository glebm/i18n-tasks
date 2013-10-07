ENV['RAKE_ENV'] ||= 'test'
require 'rspec/autorun'
$: << File.expand_path('../lib', __FILE__)

require 'i18n/tasks'
require 'rake'

Rake.load_rakefile 'tasks/i18n-tasks.rake'
Rake.load_rakefile 'support/test_codebase_env.rake'

require 'term/ansicolor'
Term::ANSIColor::coloring = false

Dir['spec/support/**/*.rb'].each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.include FixturesSupport
end