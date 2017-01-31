# frozen_string_literal: true
require 'i18n/tasks/data/tree/node'
require 'i18n/tasks/data/router/pattern_router'
require 'i18n/tasks/data/router/conservative_router'
require 'i18n/tasks/data/file_formats'
require 'i18n/tasks/key_pattern_matching'

module I18n::Tasks
  module Data
    class FileSystemBase # rubocop:disable Metrics/ClassLength
      include ::I18n::Tasks::Data::FileFormats
      include ::I18n::Tasks::Logging

      attr_reader :config, :base_locale, :locales
      attr_writer :locales

      DEFAULTS = {
        read:  ['config/locales/%{locale}.yml'],
        write: ['config/locales/%{locale}.yml']
      }.freeze

      def initialize(config = {})
        self.config  = config.except(:base_locale, :locales)
        @base_locale = config[:base_locale]
        locales = config[:locales].presence
        @locales = LocaleList.normalize_locale_list(locales || available_locales, base_locale, true)
        if locales.present?
          log_verbose "locales read from config #{@locales * ', '}"
        else
          log_verbose "locales inferred from data: #{@locales * ', '}"
        end
      end

      # get locale tree
      def get(locale)
        locale = locale.to_s
        @trees         ||= {}
        @trees[locale] ||= Tree::Siblings[locale => {}].merge!(
          read_locale(locale)
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
        forest.inject(Tree::Siblings.new) do |result, root|
          locale = root.key
          merged = get(locale).merge(root)
          set locale, merged
          result.merge! merged
        end
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
            [pattern, Dir.glob(format(pattern, locale: '*'))] if pattern.include?('%{locale}')
          end.compact.each do |pattern, paths|
            p  = pattern.gsub('\\', '\\\\').gsub('/', '\/').gsub('.', '\.')
            p  = p.gsub(/(\*+)/) { Regexp.last_match(1) == '**' ? '.*' : '[^/]*?' }.gsub('%{locale}', '([^/.]+)')
            re = /\A#{p}\z/
            paths.each do |path|
              locales << Regexp.last_match(1) if re =~ path
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
        @config = DEFAULTS.deep_merge((config || {}).reject { |_k, v| v.nil? })
        reload
      end

      def with_router(router)
        router_was  = self.router
        self.router = router
        yield
      ensure
        self.router = router_was
      end

      ROUTER_NAME_ALIASES = {
        'conservative_router' => 'I18n::Tasks::Data::Router::ConservativeRouter',
        'pattern_router' => 'I18n::Tasks::Data::Router::PatternRouter'
      }.freeze
      def router
        @router ||= begin
          name = @config[:router].presence || 'conservative_router'
          name = ROUTER_NAME_ALIASES[name] || name
          router_class = ActiveSupport::Inflector.constantize(name)
          router_class.new(self, @config.merge(base_locale: base_locale, locales: locales))
        end
      end
      attr_writer :router

      protected

      def read_locale(locale)
        Array(config[:read]).map do |path|
          Dir.glob format(path, locale: locale)
        end.reduce(:+).map do |path|
          [path.freeze, load_file(path) || {}]
        end.map do |path, data|
          filter_nil_keys! path, data
          Data::Tree::Siblings.from_nested_hash(data).tap do |s|
            s.leaves { |x| x.data.update(path: path, locale: locale) }
          end
        end.reduce(:merge!) || Tree::Siblings.null
      end

      def filter_nil_keys!(path, data, suffix = [])
        data.each do |key, value|
          if key.nil?
            data.delete(key)
            log_warn <<-TEXT
Skipping a nil key found in #{path.inspect}:
  key: #{suffix.join('.')}.`nil`
  value: #{value.inspect}
Nil keys are not supported by i18n.
The following unquoted YAML keys result in a nil key:
  #{%w(null Null NULL ~).join(', ')}
See http://yaml.org/type/null.html
TEXT
          elsif value.is_a?(Hash)
            filter_nil_keys! path, value, suffix + [key]
          end
        end
      end
    end
  end
end
