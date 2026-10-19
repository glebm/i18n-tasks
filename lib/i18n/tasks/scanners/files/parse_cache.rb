# frozen_string_literal: true

require "i18n/tasks/concurrent/cache"

module I18n::Tasks::Scanners::Files
  # Keeps the files parsed while {#retain} runs, so that scanning them again
  # (strictly, then non-strictly) does not parse them twice.
  #
  # @note This class is thread-safe.
  class ParseCache
    def retain
      @cache = ::I18n::Tasks::Concurrent::Cache.new
      yield
    ensure
      @cache = nil
    end

    # @param key [Object] identifies the parse, e.g. the scanner class and the path.
    # @yieldreturn the parse, computed only if not retained.
    def fetch(key, &)
      @cache ? @cache.fetch(key, &) : yield
    end
  end
end
