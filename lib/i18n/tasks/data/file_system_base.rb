require 'i18n/tasks/data/traversal'
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

      def config=(config)
        opt          = DEFAULTS.deep_merge((config || {}).with_indifferent_access)
        @read        = opt[:read]
        @write       = compile_routes opt[:write]
        @locale_data = {}
      end

      # get locale tree
      def get(locale)
        locale               = locale.to_s
        @locale_data[locale] ||= begin
          @read.map do |path|
            Dir.glob path % {locale: locale}
          end.reduce(:+).map do |locale_file|
            load_file locale_file
          end.inject({}.with_indifferent_access) do |hash, locale_data|
            hash.deep_merge! locale_data || {}
            hash
          end[locale.to_s] || {}
        end.with_indifferent_access
      end

      alias [] get

      # set locale tree
      def set(locale, values_tree)
        locale = locale.to_s
        route_values @write, values_tree, locale: locale do |path, data|
          write_tree path, locale => list_to_tree(data)
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
          @read.map do |pattern|
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
