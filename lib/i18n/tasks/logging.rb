# frozen_string_literal: true
module I18n::Tasks::Logging
  module_function

  MUTEX = Mutex.new
  PROGRAM_NAME = File.basename($PROGRAM_NAME)

  def warn_deprecated(message)
    log_stderr Term::ANSIColor.yellow Term::ANSIColor.bold "#{program_name}: [DEPRECATED] #{message}"
  end

  def log_verbose(message = nil)
    if ::I18n::Tasks.verbose?
      log_stderr Term::ANSIColor.bright_blue(message || yield)
    end
  end

  def log_warn(message)
    log_stderr Term::ANSIColor.yellow "#{program_name}: [WARN] #{message}"
  end

  def log_error(message)
    log_stderr Term::ANSIColor.red Term::ANSIColor.bold "#{program_name}: #{message}"
  end

  def log_stderr(*args)
    MUTEX.synchronize do
      # 1. We don't want output from different threads to get intermixed.
      # 2. StringIO is currently not thread-safe (blows up) on JRuby:
      # https://github.com/jruby/jruby/issues/4417
      $stderr.puts(*args)
    end
  end

  def program_name
    PROGRAM_NAME
  end
end
