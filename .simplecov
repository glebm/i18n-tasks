# frozen_string_literal: true

unless defined?(RUBY_ENGINE) && %w[rbx jruby].include?(RUBY_ENGINE)
  SimpleCov.skip "/spec/"
  SimpleCov.formatter SimpleCov::Formatter::HTMLFormatter unless ENV["CI"]
end
