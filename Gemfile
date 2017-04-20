# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

unless ENV['TRAVIS']
  group :development do
    gem 'byebug', platforms: %i[mri mswin x64_mingw_21 x64_mingw_22], require: false
    gem 'rubinius-debugger', platform: :rbx, require: false
  end
end

if ENV['CI']
  group :test do
    # CodeClimate coverage reporting.
    gem 'codeclimate-test-reporter', require: false
  end
end
