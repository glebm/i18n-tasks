# frozen_string_literal: true

module I18n::Tasks::Scanners::Files
  # Finds the files in the specified search paths with support for exclusion / inclusion patterns.
  #
  # @since 0.9.0
  class FileFinder
    include I18n::Tasks::Logging

    # @param paths [Array<String>] {Find.find}-compatible paths to traverse,
    #     absolute or relative to the working directory.
    # @param only [Array<String>, nil] {File.fnmatch}-compatible patterns files to include.
    #     Files not matching any of the inclusion patterns will be excluded.
    # @param exclude [Array<String>] {File.fnmatch}-compatible patterns of files to exclude.
    #     Files matching any of the exclusion patterns will be excluded even if they match an inclusion pattern.
    def initialize(paths: ["."], only: nil, exclude: [])
      fail "paths argument is required" if paths.nil?

      @paths = paths
      @include = only && split_extension_globs(only)
      @exclude = split_extension_globs(exclude || [])
    end

    # Traverse the paths and yield the matching ones.
    #
    # @yield [path]
    # @yieldparam path [String] the path of the found file.
    # @return [Array<of block results>]
    def traverse_files(&)
      find_files.map(&)
    end

    # @return [Array<String>] found files
    def find_files # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      results = []
      paths = @paths.select { |p| File.exist?(p) }
      log_warn "None of the search.paths exist #{@paths.inspect}" if paths.empty?
      Find.find(*paths) do |path|
        is_dir = File.directory?(path)
        hidden = File.basename(path).start_with?(".") && !%w[. ./].include?(path)
        not_incl = @include && !path_fnmatch_any?(path, @include)
        excl = path_fnmatch_any?(path, @exclude)
        if is_dir || hidden || not_incl || excl
          Find.prune if is_dir && (hidden || excl)
        else
          results << path
        end
      end
      results
    end

    private

    # Paths found under `.` start with `./`, which neither `*.rb` nor `app/**` match: try them without it too.
    # @param path [String]
    # @param split_globs [Array(Array<String>, Array<String>)] from {#split_extension_globs}
    # @return [Boolean]
    def path_fnmatch_any?(path, split_globs)
      path_fnmatch_split_globs?(path, split_globs) ||
        (path.start_with?("./") && path_fnmatch_split_globs?(path.delete_prefix("./"), split_globs))
    end

    # `File.fnmatch("*.png", path)` is `path.end_with?(".png")`, except for a path starting with a dot,
    # which `*` does not match without `File::FNM_DOTMATCH`.
    # @param path [String]
    # @param split_globs [Array(Array<String>, Array<String>)] from {#split_extension_globs}
    # @return [Boolean]
    def path_fnmatch_split_globs?(path, split_globs)
      suffixes, other_globs = split_globs
      (!path.start_with?(".") && path.end_with?(*suffixes)) ||
        other_globs.any? { |glob| File.fnmatch(glob, path) }
    end

    # ASCII only: `String#end_with?` raises on incompatible encodings, where `File.fnmatch` returns false.
    EXTENSION_GLOB = /\A\*(\.[\w-]+)+\z/

    # @param globs [Array<String>]
    # @return [Array(Array<String>, Array<String>)] the suffixes of the extension globs, and the other globs
    def split_extension_globs(globs)
      extension_globs, other_globs = globs.partition { |glob| EXTENSION_GLOB.match?(glob) }
      [extension_globs.map { |glob| glob.delete_prefix("*") }, other_globs]
    end
  end
end
