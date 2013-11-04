# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/tasks/version'

Gem::Specification.new do |spec|
  spec.name          = 'i18n-tasks'
  spec.version       = I18n::Tasks::VERSION
  spec.authors       = ['glebm']
  spec.email         = ['glex.spb@gmail.com']
  spec.summary       = %q{Find all the missing and unused translations!}
  spec.description   = %q{Rails I18n tasks to find missing / unused translations and more}
  spec.homepage      = 'https://github.com/glebm/i18n-tasks'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rails'
  spec.add_dependency 'rake'
  spec.add_dependency 'term-ansicolor'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'yard'
end
