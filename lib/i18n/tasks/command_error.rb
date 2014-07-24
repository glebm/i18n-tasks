# coding: utf-8
module I18n
  module Tasks
    # When this type of error is caught:
    # 1. show error message of the backtrace
    # 2. exit with non-zero exit code
    class CommandError < StandardError
    end
  end
end

