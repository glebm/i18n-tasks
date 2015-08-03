module I18n::Tasks::Scanners
  # Finds the files and provides their contents.
  #
  # @note This class is thread-safe. All methods are cached.
  # @since 0.9.0
  class FileProvider
    include I18n::Tasks::Logging

    # @param search_paths [Array<String>] {Find.find}-compatible paths to traverse,
    #     absolute or relative to the working directory.
    # @param include [Array<String>, nil] {File.fnmatch}-compatible patterns files to include.
    #     Files not matching any of the inclusion patterns will be excluded.
    # @param exclude [Arry<String>] {File.fnmatch}-compatible patterns of files to exclude.
    #     Files matching any of the exclusion patterns will be excluded even if they match an inclusion pattern.
    def initialize(search_paths: [], include: nil, exclude: [])
      @search_paths = search_paths
      @include      = include
      @exclude      = exclude

      @file_cache = {}
      @mutex      = Mutex.new
    end

    # Traverse the paths and yield the matching ones.
    #
    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @yield [path]
    # @yieldparam path [String] the path of the found file.
    # @return [Array<of block results>]
    def traverse_files
      find_paths.map { |path| yield path }
    end

    # Return the contents of the file at the given path.
    # The file is read in the 'rb' mode and assuming UTF-8 encoding.
    #
    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @param [String] path Path to the file, absolute or relative to the working directory.
    def read_file(path)
      absolute_path = File.expand_path(path)
      contents      = @file_cache[absolute_path]
      return contents if contents
      @mutex.synchronize do
        @file_cache[absolute_path] ||= begin
          result = nil
          File.open(absolute_path, 'rb', encoding: 'UTF-8') { |f| result = f.read }
          result
        end
      end
    end

    private

    # @param path [String]
    # @param globs [Array<String>]
    # @return [Boolean]
    def path_fnmatch_any?(path, globs)
      globs.any? { |glob| File.fnmatch(glob, path) }
    end

    # @return [Array<String>]
    def find_paths
      return @paths if @paths
      @mutex.synchronize do
        @paths ||= begin
          paths        = []
          search_paths = @search_paths.select { |p| File.exist?(p) }
          if search_paths.empty?
            log_warn "None of the search.paths exist #{@search_paths.inspect}"
          else
            Find.find(*search_paths) do |path|
              is_dir   = File.directory?(path)
              hidden   = File.basename(path).start_with?('.')
              not_incl = @include && !path_fnmatch_any?(path, @include)
              excl     = path_fnmatch_any?(path, @exclude)
              if is_dir || hidden || not_incl || excl
                Find.prune if is_dir && (hidden || excl)
              else
                paths << path
              end
            end
          end
          paths
        end
      end
    end
  end
end
