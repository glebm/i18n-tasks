require 'i18n/tasks/data/locale_tree'
require 'i18n/tasks/data/router'
require 'i18n/tasks/data/file_formats'
require 'i18n/tasks/key_pattern_matching'

module I18n::Tasks
  module Data
    class FileSystemBase
      include ::I18n::Tasks::Data::Router
      include ::I18n::Tasks::Data::FileFormats

      attr_reader :config

      DEFAULTS = {
          read:  ['config/locales/%{locale}.yml'],
          write: ['config/locales/%{locale}.yml']
      }.with_indifferent_access

      def initialize(config = {})
        self.config = config
      end

      def t(key, locale)
        get(locale).t(key)
      end

      def config=(config)
        @config = DEFAULTS.deep_merge((config || {}).with_indifferent_access)
        @config[:write] = compile_routes @config[:write]
        reload
      end

      # get locale tree
      def get(locale)
        locale               = locale.to_s
        @locale_data[locale] ||= begin
          hash = config[:read].map do |path|
            Dir.glob path % {locale: locale}
          end.reduce(:+).map do |locale_file|
            load_file locale_file
          end.inject({}) do |hash, locale_data|
            hash.deep_merge! locale_data || {}
            hash
          end[locale.to_s] || {}
          LocaleTree.new locale, hash.to_hash
        end
      end

      alias [] get

      # set locale tree
      def set(locale, values)
        locale = locale.to_s
        route_values config[:write], values, locale do |path, tree|
          write_tree path, tree
        end
        @locale_data[locale] = nil
      end

      alias []= set

      # @return self
      def reload
        @locale_data       = {}
        @available_locales = nil
        self
      end

      # Get available locales from the list of file names to read
      def available_locales
        @available_locales ||= begin
          locales = Set.new
          config[:read].map do |pattern|
            [pattern, Dir.glob(pattern % {locale: '*'})] if pattern.include?('%{locale}')
          end.compact.each do |pattern, paths|
            p  = pattern.gsub('\\', '\\\\').gsub('/', '\/').gsub('.', '\.')
            p  = p.gsub(/(\*+)/) { $1 == '**' ? '.*' : '[^/]*?' }.gsub('%{locale}', '([^/.]+)')
            re = /\A#{p}\z/
            paths.each do |path|
              if re =~ path
                locales << $1
              end
            end
          end
          locales
        end
      end
    end
  end
end
