# frozen_string_literal: true
unless defined?(RUBY_ENGINE) && %w(rbx jruby).include?(RUBY_ENGINE)
  SimpleCov.start do
    add_filter '/spec/'
    formatter SimpleCov::Formatter::HTMLFormatter unless ENV['TRAVIS']
  end
end
