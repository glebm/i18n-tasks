# frozen_string_literal: true

module I18n
  module Tasks
    module Scanners
      module RelativeKeys
        # @param key [String] relative i18n key (starts with a .)
        # @param path [String] path to the file containing the key
        # @param roots [Array<String>] paths to relative roots
        # @param calling_method [#call, Symbol, String, false, nil]
        # @return [String] absolute version of the key
        def absolute_key(key, path, roots: config[:relative_roots],
          exclude_method_name_paths: config[:relative_exclude_method_name_paths],
          calling_method: nil)
          return key unless key.start_with?(DOT)
          fail "roots argument is required" unless roots.present?

          cwd = Dir.pwd
          normalized_path = File.expand_path(path, cwd)
          (root = path_root(normalized_path, roots, cwd)) ||
            fail(CommandError, "Cannot resolve relative key \"#{key}\".\n" \
                               "Set search.relative_roots in config/i18n-tasks.yml (currently #{roots.inspect})")
          normalized_path.sub!(root, "")

          if expand_paths(exclude_method_name_paths || [], cwd).include?(root)
            "#{prefix(normalized_path)}#{key}"
          else
            "#{prefix(normalized_path, calling_method: calling_method)}#{key}"
          end
        end

        private

        DOT = "."

        # Detect the appropriate relative path root
        # @param [String] path /full/path
        # @param [Array<String>] roots relative or absolute paths
        # @param [String] cwd the working directory to expand the roots against
        # @return [String] the closest ancestor root for path, with a trailing {File::SEPARATOR}.
        def path_root(path, roots, cwd)
          expand_paths(roots, cwd).sort.reverse_each.detect do |root|
            path.start_with?(root)
          end
        end

        # Expanding a relative path reads the working directory, and this runs for each relative key:
        # the working directory is read once by the caller, and the paths expanded against it are kept.
        # @param [Array<String>] paths relative or absolute paths
        # @param [String] cwd the working directory to expand them against
        # @return [Array<String>] the paths expanded with {#expand_path}
        def expand_paths(paths, cwd)
          (@relative_keys_expanded_paths ||= {})[[cwd, paths]] ||= paths.map { |path| expand_path(path, cwd) }
        end

        # Expand a path and add a trailing {File::SEPARATOR}
        # @param [String] path relative or absolute path
        # @param [String] cwd the working directory to expand it against
        # @return [String] absolute path, with a trailing {File::SEPARATOR}.
        def expand_path(path, cwd)
          File.expand_path(path, cwd) + File::SEPARATOR
        end

        # @param normalized_path [String] path/relative/to/a/root
        # @param calling_method [#call, Symbol, String, false, nil]
        def prefix(normalized_path, calling_method: nil)
          file_key = normalized_path.gsub(%r{(\.[^/]+)*$}, "").tr(File::SEPARATOR, DOT)
          calling_method = calling_method.call if calling_method.respond_to?(:call)
          if calling_method&.present?
            # Relative keys in mailers have a `_mailer` infix, but relative keys in controllers do not have one:
            "#{file_key.sub(/_controller$/, "")}.#{calling_method}"
          else
            # Remove _ prefix from partials
            file_key.gsub("._", DOT)
          end
        end
      end
    end
  end
end
