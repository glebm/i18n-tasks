module I18n
  module Tasks
    module RelativeKeys
      # @param key [String] relative i18n key (starts with a .)
      # @param path [String] path to the file containing the key
      # @return [String] absolute version of the key
      def absolutize_key(key, path, roots = relative_roots)
        # normalized path
        path = File.expand_path path
        (path_root = roots.map { |path| File.expand_path path }.sort.reverse.detect { |root| path.start_with?(root + '/') }) or
            raise "No relative key root detected for \"#{key}\" at #{path}. Please set relative_roots in config/i18n-tasks.yml (currently set to #{relative_roots})"
        # key prefix based on path
        prefix = path.gsub(%r(#{path_root}/|(\.[^/]+)*$), '').tr('/', '.').gsub(%r(\._), '.')
        "#{prefix}#{key}"
      end
    end
  end
end
