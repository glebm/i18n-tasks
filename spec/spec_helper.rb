# frozen_string_literal: true

if ENV['COVERAGE'] && !%w[rbx jruby].include?(RUBY_ENGINE)
  require 'simplecov'
  SimpleCov.command_name 'RSpec'
end

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'i18n/tasks'
require 'rake'

require 'rainbow'
Rainbow.enabled = false

Dir['spec/support/**/*.rb'].each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.expose_dsl_globally = false
  config.include FixturesSupport
  config.include CaptureStd
  config.include Trees
  config.include KeysAndOccurrences
end
