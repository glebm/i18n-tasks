# coding: utf-8
require 'i18n/tasks/data/tree/node'
require 'i18n/tasks/data/router/pattern_router'
require 'i18n/tasks/data/router/conservative_router'
require 'i18n/tasks/data/file_formats'
require 'i18n/tasks/key_pattern_matching'

module I18n::Tasks
  module Data
    class FileSystemBase
      include ::I18n::Tasks::Data::FileFormats

      attr_reader :config, :base_locale

      DEFAULTS = {
          read:  ['config/locales/%{locale}.yml'],
          write: ['config/locales/%{locale}.yml']
      }.with_indifferent_access

      def initialize(config = {})
        @base_locale = config[:base_locale]
        self.config = config.except(:base_locale)
      end

      # get locale tree
      def get(locale)
        locale         = locale.to_s
        @trees         ||= {}
        @trees[locale] ||= Tree::Siblings[locale => {}].merge!(
            read_locale locale
        )
      end

      alias [] get

      # set locale tree
      def set(locale, tree)
        locale = locale.to_s
        router.route locale, tree do |path, tree_slice|
          write_tree path, tree_slice
        end
        @trees.delete(locale) if @trees
        @available_locales = nil
      end

      alias []= set

      # @return self
      def reload
        @trees             = nil
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

      def t(key, locale)
        tree = self[locale.to_s]
        return unless tree
        tree[locale][key].try(:value_or_children_hash)
      end

      def config=(config)
        @config = DEFAULTS.deep_merge((config || {}).with_indifferent_access)
        reload
      end

      def with_router(router)
        router_was  = self.router
        self.router = router
        yield
      ensure
        self.router = router_was
      end

      def router
        @router ||= begin
          name = @config[:router].presence || 'conservative_router'
          if name[0] != name[0].upcase
            name = "I18n::Tasks::Data::Router::#{name.classify}"
          end
          name.constantize.new(self, @config.merge(base_locale: base_locale))
        end
      end
      attr_writer :router

      protected

      def read_locale(locale)
        Array(config[:read]).map do |path|
          Dir.glob path % {locale: locale}
        end.reduce(:+).map do |path|
          [path.freeze, load_file(path) || {}]
        end.map do |path, data|
          Data::Tree::Siblings.from_nested_hash(data).tap do |s|
            s.leaves { |x| x.data[:path] = path }
          end
        end.reduce(:merge!) || Tree::Siblings.null
      end
    end
  end
end
