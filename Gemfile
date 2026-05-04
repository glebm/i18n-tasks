# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in i18n-tasks.gemspec
gemspec

gem "overcommit"
gem "rake"
gem "rspec", "~> 3.3"
gem "standard", require: false
gem "rubocop-rake", require: false
gem "rubocop-rspec", require: false
gem "simplecov"
gem "yard"

group :bench do
  gem "benchmark-ips", require: false
  gem "memory_profiler", require: false
end

# Translation backends
# These are only used in tests
gem "deepl-rb", ">= 2.1.0"
gem "ruby-openai"
gem "yandex-translator", ">= 0.3.3"
