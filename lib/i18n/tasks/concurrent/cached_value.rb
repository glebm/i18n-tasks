# frozen_string_literal: true

require 'i18n/tasks/concurrent/cached_value'

module I18n::Tasks::Concurrent
  # A thread-safe memoized value.
  # The given computation is guaranteed to be invoked at most once.
  # @since 0.9.25
  class CachedValue
    NULL = Object.new

    # @param [Proc] computation The computation that returns the value to cache.
    def initialize(&computation)
      @computation = computation
      @mutex = Mutex.new
      @result = NULL
    end

    # @return [Object] Result of the computation.
    def get
      return @result unless @result == NULL
      @mutex.synchronize do
        next unless @result == NULL
        @result = @computation.call
        @computation = nil
      end
      @result
    end
  end
end
