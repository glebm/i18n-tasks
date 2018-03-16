# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

platform :jruby do
  # Highline v1 does not work on JRuby 9.1.15.0:
  # https://github.com/JEG2/highline/issues/227
  gem 'highline', '>= 2.0.0.pre.develop.14'
end

platform :rbx do
  # https://github.com/rubinius/rubinius/issues/2632
  gem 'racc'
end

unless ENV['TRAVIS']
  group :development do
    gem 'byebug', platforms: %i[mri mswin x64_mingw_21 x64_mingw_22], require: false
    gem 'rubinius-debugger', platform: :rbx, require: false
  end
end

if ENV['CI']
  group :test do
    # CodeClimate coverage reporting.
    gem 'codeclimate-test-reporter', '>= 1.0.8', require: false
  end
end
