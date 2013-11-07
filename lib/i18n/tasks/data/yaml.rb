module I18n::Tasks
  module Data
    class Yaml
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def get(locale)
        options[:paths].map do |path|
          Dir.glob path % { locale: locale }
        end.flatten.map do |locale_file|
          YAML.load_file locale_file
        end.inject({}) do |hash, locale_data|
          hash.deep_merge! locale_data
          hash
        end
      end
    end
  end
end