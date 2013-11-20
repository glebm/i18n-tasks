require 'i18n/tasks/data_traversal'
require 'i18n/tasks/key_pattern_matching'
module I18n::Tasks
  module Data
    class Yaml
      include ::I18n::Tasks::DataTraversal
      include ::I18n::Tasks::KeyPatternMatching
      attr_reader :options

      DEFAULTS = {
          read:  ['config/locales/%{locale}.yml'],
          write: ['config/locales/%{locale}.yml']
      }.with_indifferent_access

      def initialize(options)
        options = (options || {}).with_indifferent_access
        if options.key?(:paths)
          options[:read] ||= options.delete(:paths)
          ::I18n::Tasks.warn_deprecated 'please rename "data.paths" key to "data.read" in config/i18n-tasks.yml'
        end
        options[:write]
        options = DEFAULTS.deep_merge(options)
        @read   = options[:read]
        @write  = options[:write].map { |x| x.is_a?(String) ? ['*', x] : x }.map { |x|
          [key_pattern_to_re(x[0]), x[1]]
        }
      end

      # get locale tree
      def get(locale)
        locale                        = locale.to_s
        (@locale_data ||= {})[locale] ||= begin
          @read.map do |path|
            Dir.glob path % {locale: locale}
          end.flatten.map do |locale_file|
            YAML.load_file locale_file
          end.inject({}) do |hash, locale_data|
            hash.deep_merge! locale_data || {}
            hash
          end[locale.to_s]
        end
      end

      alias [] get

      # set locale tree
      def set(locale, value_tree)
        out = {}
        traverse value_tree do |key, value|
          route = @write.detect { |route| route[0] =~ key }
          (out[route[1] % {locale: locale}] ||= []) << [key, value]
        end
        out.each do |path, data|
          File.open(path, 'w') { |f|
            f.write({locale.to_s => list_to_tree(data)}.to_yaml)
          }
        end
      end

      alias []= set
    end
  end
end