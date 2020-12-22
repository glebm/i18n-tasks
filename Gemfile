# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

platform :rbx do
  # https://github.com/rubinius/rubinius/issues/2632
  gem 'racc'
end

unless ENV['TRAVIS']
  group :development do
    gem 'byebug', platforms: %i[mri mswin x64_mingw_21 x64_mingw_22], require: false # rubocop:disable Naming/VariableNumber
    gem 'rubinius-debugger', platform: :rbx, require: false
  end
end
