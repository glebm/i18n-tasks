unless !ENV['COVERAGE'] || defined?(RUBY_ENGINE) && %w(rbx jruby).include?(RUBY_ENGINE)
  ENV['SIMPLECOV_NO_DEFAULTS'] = '1'
  require 'simplecov'
  SimpleCov.command_name "bin/i18n-tasks #{ARGV.join ' '}".strip
  SimpleCov.root File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require 'simplecov/defaults'
  SimpleCov::Formatter::HTMLFormatter.send(:define_method, :puts) { |*| }
  if defined?(CodeClimate)
    class NullLoger < Logger
      def initialize(*args)
      end

      def add(*args, &block)
      end
    end
    CodeClimate::TestReporter.configuration.logger = NullLoger.new
  end
end
