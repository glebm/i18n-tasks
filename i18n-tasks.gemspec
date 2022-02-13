# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/tasks/version'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = 'i18n-tasks'
  s.version       = I18n::Tasks::VERSION
  s.authors       = ['glebm']
  s.email         = ['glex.spb@gmail.com']
  s.license       = 'MIT'
  s.summary       = 'Manage localization and translation with the awesome power of static analysis'
  s.description   = <<~TEXT
    i18n-tasks helps you find and manage missing and unused translations.

    It analyses code statically for key usages, such as `I18n.t('some.key')`, in order to report keys that are missing or unused,
    pre-fill missing keys (optionally from Google Translate), and remove unused keys.
  TEXT
  s.post_install_message = <<~TEXT
    # Install default configuration:
    cp $(bundle exec i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
    # Add an RSpec for missing and unused keys:
    cp $(bundle exec i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
  TEXT
  s.homepage = 'https://github.com/glebm/i18n-tasks'
  s.metadata = { 'issue_tracker' => 'https://github.com/glebm/i18n-tasks' } if s.respond_to?(:metadata=)
  s.required_ruby_version = '>= 2.6', '< 4.0' if s.respond_to?(:required_ruby_version=)

  s.files = `git ls-files`.split($/)
  s.files -= s.files.grep(%r{^(doc/|\.|spec/)}) + %w[CHANGES.md config/i18n-tasks.yml Gemfile]
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) } - %w[i18n-tasks.cmd]
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'activesupport', '>= 4.0.2'
  s.add_dependency 'ast', '>= 2.1.0'
  s.add_dependency 'better_html', '~> 1.0'
  s.add_dependency 'erubi'
  s.add_dependency 'highline', '>= 2.0.0'
  s.add_dependency 'i18n'
  s.add_dependency 'parser', '>= 2.2.3.0'
  s.add_dependency 'rails-i18n'
  s.add_dependency 'rainbow', '>= 2.2.2', '< 4.0'
  s.add_dependency 'terminal-table', '>= 1.5.1'
  s.add_development_dependency 'axlsx', '~> 2.0'
  s.add_development_dependency 'bundler', '~> 2.0', '>= 2.0.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '~> 1.6.1'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'

  # Translation backends
  s.add_development_dependency 'deepl-rb', '>= 2.1.0'
  s.add_development_dependency 'easy_translate', '>= 0.5.1' # Google Translate
  s.add_development_dependency 'yandex-translator', '>= 0.3.3'
end
