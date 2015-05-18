# coding: utf-8
require 'active_support/core_ext/kernel/reporting'
module CaptureStd
  def capture_stderr
    err, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = err
  end

  def capture_stdout
    out, $stdout = $stdout, StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = out
  end

  def silence_stderr(&block)
    silence_stream($stderr, &block)
  end
end
