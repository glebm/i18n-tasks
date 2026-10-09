# frozen_string_literal: true

unless defined?(RUBY_ENGINE) && %w[rbx jruby].include?(RUBY_ENGINE)
  if SimpleCov.respond_to?(:skip)
    SimpleCov.skip "/spec/"
  else
    SimpleCov.add_filter "/spec/"
  end
  SimpleCov.formatter SimpleCov::Formatter::HTMLFormatter unless ENV["CI"]
end
