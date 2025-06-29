# frozen_string_literal: true

require "active_support/testing/stream"

module CaptureStd
  include ActiveSupport::Testing::Stream if defined?(ActiveSupport::Testing::Stream)

  def capture_stderr
    return yield if ENV["NOSILENCE"]

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
    return yield if ENV["NOSILENCE"]

    begin
      out = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = out
    end
  end

  def silence_stderr(&)
    return yield if ENV["NOSILENCE"]

    silence_stream($stderr, &)
  end
end
