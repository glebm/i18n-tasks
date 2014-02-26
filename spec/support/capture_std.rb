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
end
