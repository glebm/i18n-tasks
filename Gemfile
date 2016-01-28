source 'https://rubygems.org'

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

unless ENV['TRAVIS']
  group :development do
    gem 'byebug', platforms: [:mri_21, :mri_22, :mri_23, :mswin, :x64_mingw_21, :x64_mingw_22], require: false
    gem 'rubinius-debugger', platform: :rbx, require: false
  end
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'codeclimate_batch', require: nil
end
