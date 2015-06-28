# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/tasks/version'

Gem::Specification.new do |s|
  s.name          = 'i18n-tasks'
  s.version       = I18n::Tasks::VERSION
  s.authors       = ['glebm']
  s.email         = ['glex.spb@gmail.com']
  s.summary       = %q{Manage localization and translation with the awesome power of static analysis}
  s.description   = <<-TEXT
i18n-tasks helps you find and manage missing and unused translations.

It analyses code statically for key usages, such as `I18n.t('some.key')`, in order to report keys that are missing or unused,
pre-fill missing keys (optionally from Google Translate), and remove unused keys.
TEXT
  s.post_install_message = <<-TEXT
# Install default configuration:
cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
# Add an RSpec for missing and unused keys:
cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
TEXT
  s.homepage      = 'https://github.com/glebm/i18n-tasks'
  if s.respond_to?(:metadata=)
    s.metadata = { 'issue_tracker' => 'https://github.com/glebm/i18n-tasks' }
  end
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.files         -= s.files.grep(%r{^doc/img/})
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'erubis'
  s.add_dependency 'activesupport'
  s.add_dependency 'easy_translate', '>= 0.5.0'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'terminal-table', '>= 1.5.1'
  s.add_dependency 'highline'
  s.add_dependency 'i18n'
  s.add_development_dependency 'axlsx', '~> 2.0'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'yard'
end
