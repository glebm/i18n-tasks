source 'https://rubygems.org'

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

unless ENV['TRAVIS']
  group :development do
    gem 'byebug', platforms: [:mri_21, :mri_22], require: false
    gem 'rubinius-debugger', platform: :rbx, require: false
  end
end

gem 'codeclimate-test-reporter', group: :test, require: nil
