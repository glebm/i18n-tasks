require 'i18n/tasks/scanners/files/caching_file_finder'

module I18n::Tasks::Scanners::Files
  # Finds the files and provides their contents.
  #
  # @note This class is thread-safe. All methods are cached.
  # @since 0.9.0
  class CachingFileFinderProvider
    def initialize
      @cache = {}
      @mutex = Mutex.new
    end

    # Initialize a {CachingFileFinder} or get one from cache based on the constructor arguments.
    #
    # @param (see FileFinder#initialize)
    # @return [CachingFileFinder]
    def get(**file_finder_args)
      @cache[file_finder_args] || @mutex.synchronize do
        @cache[file_finder_args] ||= CachingFileFinder.new(**file_finder_args)
      end
    end
  end
end
