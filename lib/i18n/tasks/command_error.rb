module I18n
  module Tasks
    # When this type of error is caught:
    # 1. show error message of the backtrace
    # 2. exit with non-zero exit code
    class CommandError < StandardError

      def initialize(error = nil, message)
        super(message)
        set_backtrace error.backtrace if error
      end
    end
  end
end

