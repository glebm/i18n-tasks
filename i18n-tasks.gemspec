# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/tasks/version'

Gem::Specification.new do |s|
  s.name          = 'i18n-tasks'
  s.version       = I18n::Tasks::VERSION
  s.authors       = ['glebm']
  s.email         = ['glex.spb@gmail.com']
  s.summary       = %q{Tasks to manage missing and unused translations in ruby applications using I18n.}
  s.description   = %q{
    rake tasks to find unused and missing translations, normalize locale files,
    and prefill missing keys. Supports relative and plural keys and Google Translate.
}
  s.homepage      = 'https://github.com/glebm/i18n-tasks'
  if s.respond_to?(:metadata=)
    s.metadata = { 'issue_tracker' => 'https://github.com/glebm/i18n-tasks' }
  end
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/) - %w(doc/img/i18n-tasks.gif doc/img/i18n-usages.png)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'rake'
  s.add_dependency 'erubis'
  s.add_dependency 'activesupport'
  s.add_dependency 'easy_translate', '>= 0.4.0'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'terminal-table'
  s.add_dependency 'highline'
  s.add_development_dependency 'axlsx', '~> 2.0'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
end
