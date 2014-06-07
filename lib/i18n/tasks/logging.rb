module I18n::Tasks::Logging
  def warn_deprecated(message)
    log_stderr Term::ANSIColor.yellow Term::ANSIColor.bold "i18n-tasks: [DEPRECATED] #{message}"
  end

  def log_verbose(message)
    if ENV['VERBOSE']
      log_stderr Term::ANSIColor.green "i18n-tasks: #{message}"
    end
  end

  def log_warn(message)
    log_stderr Term::ANSIColor.yellow "i18n-tasks: [WARN] #{message}"
  end

  def log_error(message)
    log_stderr Term::ANSIColor.red Term::ANSIColor.bold "i18n-tasks: #{message}"
  end

  def log_stderr(*args)
    STDERR.puts *args
  end
end
