# coding: utf-8
ENV['RAILS_ENV'] = ENV['RAKE_ENV'] = 'test'

if ENV['TRAVIS'] && !(defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx')
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$: << File.expand_path('../lib', __FILE__)

require 'i18n/tasks'
require 'rake'

require 'term/ansicolor'
Term::ANSIColor::coloring = false

Dir['spec/support/**/*.rb'].each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.include FixturesSupport
  config.include CaptureStd
  config.include Trees
end
