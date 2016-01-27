# frozen_string_literal: true
require 'i18n/tasks/scanners/files/file_finder'
module I18n::Tasks::Scanners::Files
  # Finds the files in the specified search paths with support for exclusion / inclusion patterns.
  # Wraps a {FileFinder} and caches the results.
  #
  # @note This class is thread-safe. All methods are cached.
  # @since 0.9.0
  class CachingFileFinder < FileFinder
    # @param (see FileFinder#initialize)
    def initialize(**args)
      super
      @mutex = Mutex.new
      @cached_paths = nil
    end

    # Traverse the paths and yield the matching ones.
    #
    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @param (see FileFinder#traverse_files)
    # @yieldparam (see FileFinder#traverse_files)
    # @return (see FileFinder#traverse_files)
    def traverse_files
      super
    end

    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @return (see FileFinder#find_files)
    def find_files
      @cached_paths || @mutex.synchronize { @cached_paths ||= super }
    end
  end
end
