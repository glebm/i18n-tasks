module I18n::Tasks
  module Data
    class Yaml
      attr_reader :options

      DEFAULTS = {
          read: %w('app/')
      }.with_indifferent_access

      def initialize(options)
        options = (options || {}).with_indifferent_access
        if options.key?(:paths)
          options[:read] ||= options.delete(:paths)
          ::I18n::Tasks.warn_deprecated 'please rename "data.paths" key to "data.read" in config/i18n-tasks.yml'
        end
        @options = DEFAULTS.deep_merge(options)
      end

      def get(locale)
        options[:read].map do |path|
          Dir.glob path % { locale: locale }
        end.flatten.map do |locale_file|
          YAML.load_file locale_file
        end.inject({}) do |hash, locale_data|
          hash.deep_merge! locale_data || {}
          hash
        end
      end
    end
  end
end