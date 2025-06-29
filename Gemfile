# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

platform :rbx do
  # https://github.com/rubinius/rubinius/issues/2632
  gem "racc"
end

gem "bundler", "~> 2.0", ">= 2.0.1"
gem "overcommit"
gem "rake"
gem "rspec", "~> 3.3"
gem "standard", require: false
gem "rubocop-rake", require: false
gem "rubocop-rspec", require: false
gem "simplecov"
gem "yard"

# Translation backends
# These are only used in tests
gem "deepl-rb", ">= 2.1.0"
gem "easy_translate", ">= 0.5.1" # Google Translate
gem "ruby-openai"
gem "yandex-translator", ">= 0.3.3"

unless ENV["CI"]
  group :development do
    gem "byebug", platforms: %i[mri mswin x64_mingw_21 x64_mingw_22], require: false # rubocop:disable Naming/VariableNumber
    gem "rubinius-debugger", platform: :rbx, require: false
  end
end
