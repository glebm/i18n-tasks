unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  ENV['SIMPLECOV_NO_DEFAULTS'] = '1'
  require 'simplecov'
  SimpleCov.command_name "bin/i18n-tasks #{ARGV.join ' '}".strip
  SimpleCov.root File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require 'simplecov/defaults'
  SimpleCov::Formatter::HTMLFormatter.send(:define_method, :puts) { |*|}
end
