# coding: utf-8
module I18n
  module Tasks
    module Scanners
      module RelativeKeys
        # @param key [String] relative i18n key (starts with a .)
        # @param path [String] path to the file containing the key
        # @return [String] absolute version of the key
        def absolutize_key(key, path, roots = relative_roots, closest_method = "")
          normalized_path = File.expand_path(path)
          path_root(normalized_path, roots) or
            raise CommandError.new(
              "Error scanning #{normalized_path}: cannot resolve relative key
              \"#{key}\".\nSet relative_roots in config/i18n-tasks.yml
              (currently #{relative_roots.inspect})"
            )

          prefix_key_based_on_path(key, normalized_path, roots, closest_method: closest_method)
        end

        private

        def path_root(path, roots)
          @path_root ||=
            expanded_relative_roots(roots).detect do |root|
              path.start_with?(root + '/')
            end
        end

        def expanded_relative_roots(roots)
          roots.map { |path| File.expand_path(path) }
        end

        def prefix_key_based_on_path(key, normalized_path, roots, options = {})
          "#{prefix(normalized_path, roots, options)}#{key}"
        end

        def prefix(normalized_path, roots, options = {})
          file_name = normalized_path.gsub(%r(#{path_root(normalized_path, roots)}/|(\.[^/]+)*$), '')

          if /controllers/.match(normalized_path)
            "#{file_name.split("_").first}.#{options[:closest_method]}"
          else
            file_name.tr('/', '.').gsub(%r(\._), '.')
          end
        end
      end
    end
  end
end
