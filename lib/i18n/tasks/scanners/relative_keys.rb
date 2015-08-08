module I18n
  module Tasks
    module Scanners
      module RelativeKeys
        # @param key [String] relative i18n key (starts with a .)
        # @param path [String] path to the file containing the key
        # @param roots [Array<String>] paths to relative roots
        # @param calling_method [Symbol, String, nil]
        # @return [String] absolute version of the key
        def absolutize_key(key, path, roots, calling_method = nil)
          fail 'roots argument is required' if roots.nil?
          normalized_path = File.expand_path(path)
          path_root(normalized_path, roots) or
            fail CommandError.new(
              "Error scanning #{normalized_path}: cannot resolve relative key
              \"#{key}\".\nSet search.relative_roots in config/i18n-tasks.yml
              (currently #{roots.inspect})")

          prefix_key_based_on_path(key, normalized_path, roots, calling_method: calling_method)
        end

        private

        # Detect the appropriate relative path root
        # @param [String] path /full/path
        # @param [Array<String>] roots array of full paths
        # @return [String] the closest ancestor root for path
        def path_root(path, roots)
          expanded_relative_roots(roots).sort.reverse_each.detect do |root|
            path.start_with?(root + '/'.freeze)
          end
        end

        def expanded_relative_roots(roots)
          roots.map { |path| File.expand_path(path) }
        end

        def prefix_key_based_on_path(key, normalized_path, roots, options = {})
          "#{prefix(normalized_path, roots, options)}#{key}"
        end

        def prefix(normalized_path, roots, options = {})
          file_name = normalized_path.gsub(%r(#{path_root(normalized_path, roots)}/|(\.[^/]+)*$), ''.freeze)

          if options[:calling_method].present?
            controller_name = file_name.sub(/_controller$/, ''.freeze)
            "#{controller_name}.#{options[:calling_method]}".tr('/'.freeze, '.'.freeze)
          else
            file_name.tr('/'.freeze, '.'.freeze).gsub(%r(\._), '.'.freeze)
          end
        end
      end
    end
  end
end
