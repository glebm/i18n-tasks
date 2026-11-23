# frozen_string_literal: true

require "i18n/tasks/data/tree/node"
require "i18n/tasks/data/router/pattern_router"
require "i18n/tasks/data/router/conservative_router"
require "i18n/tasks/data/router/isolating_router"
require "i18n/tasks/data/file_formats"
require "i18n/tasks/key_pattern_matching"

module I18n::Tasks
  module Data
    class FileSystemBase # rubocop:disable Metrics/ClassLength
      include ::I18n::Tasks::Data::FileFormats
      include ::I18n::Tasks::Logging

      attr_accessor :locales
      attr_reader :config, :base_locale
      attr_writer :router

      DEFAULTS = {
        read: ["config/locales/%{locale}.yml"],
        write: ["config/locales/%{locale}.yml"]
      }.freeze

      def initialize(config = {})
        self.config = config.except(:base_locale, :locales)
        self.config[:sort] = !config[:keep_order]
        @base_locale = config[:base_locale]
        locales = config[:locales].presence
        @locales = LocaleList.normalize_locale_list(locales || available_locales, base_locale, true)
        if locales.present?
          log_verbose "locales read from config #{@locales * ", "}"
        else
          log_verbose "locales inferred from data: #{@locales * ", "}"
        end
      end

      # @param [String, Symbol] locale
      # @return [::I18n::Tasks::Data::Siblings]
      def get(locale)
        locale = locale.to_s
        @trees ||= {}
        @trees[locale] ||= read_locale(locale)
      end

      alias_method :[], :get

      # @param [String, Symbol] locale
      # @return [::I18n::Tasks::Data::Siblings]
      def external(locale)
        locale = locale.to_s
        @external ||= {}
        @external[locale] ||= read_locale(locale, paths: config[:external])
      end

      # set locale tree
      # @param [String, Symbol] locale
      # @param [::I18n::Tasks::Data::Siblings] tree
      #   Only the `locale` root is routed. Files holding several locales are written with the other locales from `tree`
      #   for those it holds (a command may have changed them), else as read.
      def set(locale, tree)
        locale = locale.to_s
        @trees&.delete(locale)
        read = get(locale)
        own = Tree::Siblings.new(nodes: [tree.key_to_node[locale]].compact)
        # The files the locale's keys were read from, including those that aren't its own (e.g. `en-GB` keys in `en.yml`)
        moved_from = isolating_router? ? [] : own.leaves.reject { |node| node.data.key?(:missing_diff_locale) }
        paths_before = Set.new((read[locale].leaves.to_a + moved_from).filter_map { |node| node.data[:path] })
        slices = {}
        router.route(locale, own) { |path, tree_slice| slices[path] = tree_slice }
        forest = Tree::Siblings.new(nodes: tree.to_a + read.reject { |root| tree.key_to_node.key?(root.key) })
        # A file that fails to parse is overwritten, as before
        others = other_locales_by_path(locale, forest, read, paths_before | slices.keys) { Tree::Siblings.new }
        slices.each do |path, tree_slice|
          write_tree path, tree_slice.merge(others[path]), config[:sort]
        end
        (paths_before - slices.keys).each do |path|
          next unless File.exist?(path)

          others[path].empty? ? FileUtils.remove_file(path) : write_tree(path, others[path], config[:sort])
        end
        # Other locales' trees are stale once a file they were read from is written.
        shared = others.values.any?(&:present?) || Array(config[:read]).any? { |pattern| !pattern.include?("%{locale}") }
        shared ? reload : @trees&.delete(locale)
        @read_paths = nil
        @available_locales = nil
      end

      alias_method :[]=, :set

      # @param [String] locale
      # @return [Array<String>] paths to files that are not normalized
      def non_normalized_paths(locale)
        locale = locale.to_s
        read = get(locale)
        slices = router.route(locale, read).to_h
        others = other_locales_by_path(locale, read, read, slices.keys) { nil } # a file that fails to parse is not normalized
        slices.reject { |path, tree_slice| others[path] && normalized?(path, tree_slice.merge(others[path])) }.keys
      end

      def write(forest)
        # An adapter overriding `set` gets one locale, as before
        whole = method(:set).owner == FileSystemBase
        forest.each { |root| set(root.key, whole ? forest : root.to_siblings) }
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
          locale = root.key
          locale_data = get(locale)
          subtracted = locale_data.subtract_by_key(forest)
          # An emptied root stays, so that `set` empties it in a file holding several locales instead of keeping it as read
          subtracted.merge!(locale_data.to_h { |node| [node.key, {}] })
          set locale, subtracted
          removed.merge! locale_data.subtract_by_key(subtracted)
        end
      end

      # @return self
      def reload
        @trees = nil
        @read_paths = nil
        @available_locales = nil
        self
      end

      # Whether `get(locale)` reads the file at `path`, and so holds all of its locales
      def read_for?(path, locale)
        @read_paths ||= {}
        (@read_paths[locale.to_s] ||= read_paths(locale.to_s).to_set).include?(path)
      end

      # Get available locales from the list of file names to read
      def available_locales
        @available_locales ||= begin
          locales = Set.new
          Array(config[:read]).map do |pattern|
            [pattern, Dir.glob(format(pattern, locale: "*"))] if pattern.include?("%{locale}")
          end.compact.each do |pattern, paths|
            p = pattern.gsub("\\", "\\\\").gsub("/", '\/').gsub(".", '\.')
            p = p.gsub(/(\*+)/) { (Regexp.last_match(1) == "**") ? ".*" : "[^/]*?" }.gsub("%{locale}", "([^/.]+)")
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
        @config = DEFAULTS.deep_merge((config || {}).compact)
        reload
      end

      def with_router(router)
        router_was = self.router
        self.router = router
        yield
      ensure
        self.router = router_was
      end

      ROUTER_NAME_ALIASES = {
        "conservative_router" => "I18n::Tasks::Data::Router::ConservativeRouter",
        "isolating_router" => "I18n::Tasks::Data::Router::IsolatingRouter",
        "pattern_router" => "I18n::Tasks::Data::Router::PatternRouter"
      }.freeze
      def router
        @router ||= begin
          name = @config[:router].presence || "conservative_router"
          name = ROUTER_NAME_ALIASES[name] || name
          router_class = ActiveSupport::Inflector.constantize(name)
          router_class.new(self, @config.merge(base_locale: base_locale, locales: locales))
        end
      end

      protected

      # A file can hold several locales (e.g. `all.yml`, or `en-GB` keys in `en.yml`), and writing one locale must keep
      # the others' keys (the whole file is normalized). Those in the file are written with their values in `forest`
      # (a command may have changed or removed them), while those it doesn't have yet are left to their own locale.
      # @param read [Tree::Siblings] the data read for `locale`
      # @yieldreturn what to use for a file that fails to parse, instead of raising
      # @return [Hash{String => Tree::Siblings}] the other locales' keys in each of `paths`
      def other_locales_by_path(locale, forest, read, paths)
        return Hash.new { Tree::Siblings.new } if isolating_router?

        others = Tree::Siblings.new(nodes: forest.reject { |root| root.key == locale })
        read_keys = Hash.new { |hash, path| hash[path] = Set.new }
        read.each { |root| root.leaves { |leaf| read_keys[leaf.data[:path]] << key_parts(leaf) } unless root.key == locale }
        paths.to_h do |path|
          if read_for?(path, locale)
            in_file, on_disk = read_keys[path], Tree::Siblings.new
          else
            on_disk = other_locales_on_disk(path, locale)
            in_file = Set.new(on_disk.leaves.map { |leaf| key_parts(leaf) })
            on_disk = Tree::Siblings.new(nodes: on_disk.reject { |root| others.key_to_node.key?(root.key) })
          end
          # By key rather than by path: a key moved or routed elsewhere still carries the path it was read from
          leaves = in_file.filter_map { |key| others.dig(*key) }.reject(&:children?)
          [path, select_leaves(others, leaves).merge(on_disk)]
        rescue CommandError
          raise unless block_given?

          [path, yield]
        end
      end

      def key_parts(node)
        node.walk_from_root.map(&:key)
      end

      # @return [Siblings] the subtree of forest holding these leaves, without walking the rest of the forest
      def select_leaves(forest, leaves)
        selected = Set.new
        leaves.each { |leaf| leaf.walk_to_root { |node| break unless selected.add?(node) } }
        forest.select_nodes { |node| selected.include?(node) }
      end

      # @return [Tree::Siblings] the roots of locales other than `locale` in the file at `path`
      def other_locales_on_disk(path, locale)
        file_data = (load_file(path) if File.file?(path) && !read_file(path).b.strip.empty?) # a blank file is overwritten
        return Tree::Siblings.new unless file_data.is_a?(Hash)

        filter_nil_keys! path, file_data
        file_data = file_data.transform_keys(&:to_s).reject { |key, _| key == locale }
        Tree::Siblings.from_nested_hash(file_data)
      end

      def isolating_router?
        router.is_a?(Router::IsolatingRouter)
      end

      def read_paths(locale, paths: config[:read])
        Array(paths).flat_map { |path| Dir.glob format(path, locale: locale) }
      end

      def read_locale(locale, paths: config[:read])
        read_paths(locale, paths: paths).map do |path|
          [path.freeze, load_file(path) || {}]
        end.map do |path, data|
          if isolating_router?
            data.transform_values! { |tree| {"<#{router.alternate_path_for(path, base_locale)}>" => tree} }
          end
          filter_nil_keys! path, data
          Data::Tree::Siblings.from_nested_hash(data).tap do |s|
            s.leaves { |x| x.data.update(path: path, locale: locale) }
          end
        end.reduce(Tree::Siblings[locale => {}], :merge!)
      end

      def filter_nil_keys!(path, data, suffix = [])
        data.each do |key, value|
          if key.nil?
            data.delete(key)
            log_warn <<~TEXT
              Skipping a nil key found in #{path.inspect}:
                key: #{suffix.join(".")}.`nil`
                value: #{value.inspect}
              Nil keys are not supported by i18n.
              The following unquoted YAML keys result in a nil key:
                #{%w[null Null NULL ~].join(", ")}
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
