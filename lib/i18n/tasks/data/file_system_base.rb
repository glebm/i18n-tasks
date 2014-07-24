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
      include ::I18n::Tasks::Logging

      attr_reader :config, :base_locale, :locales
      attr_accessor :locales

      DEFAULTS = {
          read:  ['config/locales/%{locale}.yml'],
          write: ['config/locales/%{locale}.yml']
      }.with_indifferent_access

      def initialize(config = {})
        self.config  = config.except(:base_locale, :locales)
        @base_locale = config[:base_locale]
        locales = config[:locales].presence
        @locales = LocaleList.normalize_locale_list(locales || available_locales, base_locale, true)
        if locales.present?
          log_verbose "data locales: #{@locales}"
        else
          log_verbose "data locales (inferred): #{@locales}"
        end
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

      def write(forest)
        forest.each { |root| set(root.key, root) }
      end

      def merge!(forest)
        forest.inject(Tree::Siblings.new) { |result, root|
          locale = root.key
          merged = get(locale).merge(root)
          set locale, merged
          result.merge! merged
        }
      end

      def remove_by_key!(forest)
        forest.inject(Tree::Siblings.new) do |removed, root|
          locale_data = get(root.key)
          subtracted = locale_data.subtract_by_key(forest)
          set root.key, subtracted
          removed.merge! locale_data.subtract_by_key(subtracted)
        end
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
          Array(config[:read]).map do |pattern|
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
          name.constantize.new(self, @config.merge(base_locale: base_locale, locales: locales))
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
            s.leaves { |x| x.data.update(path: path, locale: locale) }
          end
        end.reduce(:merge!) || Tree::Siblings.null
      end
    end
  end
end
