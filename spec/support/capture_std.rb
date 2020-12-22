# frozen_string_literal: true

# This is necessary because Rails 5 removed the Kernel extension of
# that added `#silence_stream` and moved it to their testing set of
# libraries. Therefore, I'm including this here. Technically any
# testing will conceivably install version 5 meaning the include is
# necessary. However, this allows us to clearly be compliant with
# both rails 4 and 5 which the gemspec supports.
require 'active_support/gem_version'

if ActiveSupport::VERSION::MAJOR == 4
  require 'active_support/core_ext/kernel/reporting'
else
  require 'active_support/testing/stream'
end

module CaptureStd
  include ActiveSupport::Testing::Stream if defined?(ActiveSupport::Testing::Stream)

  def capture_stderr
    return yield if ENV['NOSILENCE']

    begin
      err = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = err
    end
  end

  def capture_stdout
    return yield if ENV['NOSILENCE']

    begin
      out = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = out
    end
  end

  def silence_stderr(&block)
    return yield if ENV['NOSILENCE']

    silence_stream($stderr, &block)
  end
end
