# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/tasks/version'

Gem::Specification.new do |s|
  s.name          = 'i18n-tasks'
  s.version       = I18n::Tasks::VERSION
  s.authors       = ['glebm']
  s.email         = ['glex.spb@gmail.com']
  s.summary       = %q{Manage translations in ruby applications with the awesome power of static analysis — Edit}
  s.description   = %q{
The basic approach to i18n key management in frameworks such as Rails is far from perfect.
If you use a key that does not exist, this will only blow up at runtime. Keys left over from removed code accumulate
in the resource files, introducing unnecessary overhead on the translators. Translation files can quickly turn to disarray.

i18n-tasks improves this by using static analysis. It provides tasks to find and manage missing and unused translations.
This information is inferred based on the keys the gem detects used with calls such as `I18n.t` when scanning the code.
}
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
  s.add_dependency 'easy_translate', '>= 0.4.0'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'terminal-table'
  s.add_dependency 'highline'
  s.add_dependency 'slop', '>= 3.4.7'
  s.add_development_dependency 'axlsx', '~> 2.0'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
end
