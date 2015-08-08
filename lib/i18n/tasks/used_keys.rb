require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'
require 'i18n/tasks/scanners/ruby_ast_scanner'
require 'i18n/tasks/scanners/scanner_multiplexer'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'
require 'i18n/tasks/scanners/files/caching_file_reader'

module I18n::Tasks
  module UsedKeys
    SEARCH_DEFAULTS = {
        paths:          %w(app/).freeze,
        relative_roots: %w(app/controllers app/helpers app/mailers app/presenters app/views).freeze,
        scanners:       [['::I18n::Tasks::Scanners::RubyAstScanner', include: %w(*.rb).freeze],
                         ['::I18n::Tasks::Scanners::PatternWithScopeScanner',
                          exclude:      %w(*.rb).freeze,
                          ignore_lines: {'rb'     => %q(^\s*#(?!\si18n-tasks-use)),
                                         'opal'   => %q(^\s*#(?!\si18n-tasks-use)),
                                         'haml'   => %q(^\s*-\s*#(?!\si18n-tasks-use)),
                                         'slim'   => %q(^\s*(?:-#|/)(?!\si18n-tasks-use)),
                                         'coffee' => %q(^\s*#(?!\si18n-tasks-use)),
                                         'erb'    => %q(^\s*<%\s*#(?!\si18n-tasks-use))}.freeze]
                        ].freeze,
        strict:         true,
    }.freeze

    SEARCH_CONFIG_ALWAYS_EXCLUDE = %w(*.jpg *.png *.gif *.svg *.ico *.eot *.otf *.ttf *.woff *.woff2 *.pdf *.css *.sass
                                      *.scss *.less *.yml *.json).freeze

    # Find all keys in the source and return a forest with the keys in absolute form and their occurrences.
    #
    # @param key_filter [String] only return keys matching this pattern.
    # @param strict [Boolean] if true, dynamic keys are excluded (e.g. `t("category.#{ category.key }")`)
    # @return [Data::Tree::Siblings]
    def used_tree(key_filter: nil, strict: nil)
      keys = ((@used_tree ||= {})[strict?(strict)] ||= scanner(strict: strict).keys.freeze)
      if key_filter
        key_filter_re = compile_key_pattern(key_filter)
        keys          = keys.reject { |k| k.key !~ key_filter_re }
      end
      Data::Tree::Node.new(
          key:      'used',
          data:     {key_filter: key_filter},
          children: Data::Tree::Siblings.from_key_occurrences(keys)
      ).to_siblings
    end

    def scanner(strict: nil)
      (@scanner ||= {})[strict.nil? ? search_config[:strict] : strict] ||= begin
        shared_options = search_config.dup
        shared_options.delete(:scanners)
        shared_options[:strict] = strict unless strict.nil?
        Scanners::ScannerMultiplexer.new(
            scanners: search_config[:scanners].map { |(class_name, args)|
              if args && args[:strict]
                fail CommandError.new('the strict option is global and cannot be applied on the scanner level')
              end
              ActiveSupport::Inflector.constantize(class_name).new(
                  config:               shared_options.deep_merge(args || {}),
                  file_finder_provider: caching_file_finder_provider,
                  file_reader:          caching_file_reader)
            })
      end
    end

    def search_config
      @search_config ||= apply_default_scanner_config((config[:search] || {}).dup.deep_symbolize_keys).freeze
    end

    def apply_default_scanner_config(conf)
      conf[:strict] = SEARCH_DEFAULTS[:strict] unless conf.key?(:strict)
      if conf[:scanner]
        warn_deprecated 'search.scanner is now search.scanners, an array of [ScannerClass, options]'
        conf[:scanners] = [[conf.delete(:scanner)]]
      end
      conf[:scanners] ||= SEARCH_DEFAULTS[:scanners]
      if conf[:relative_roots].blank?
        conf[:relative_roots] = SEARCH_DEFAULTS[:relative_roots]
      end
      conf[:paths]   = SEARCH_DEFAULTS[:paths] if conf[:paths].blank?
      conf[:include] = Array(conf[:include]) if conf[:include].present?
      conf[:exclude] = Array(conf[:exclude]) + SEARCH_CONFIG_ALWAYS_EXCLUDE
      if conf[:ignore_lines]
        warn_deprecated 'search.ignore_lines is no longer a global setting: pass it directly to the pattern scanner.'
        conf.delete(:ignore_lines)
      end
      conf
    end


    def caching_file_finder_provider
      @caching_file_finder_provider ||= Scanners::Files::CachingFileFinderProvider.new
    end

    def caching_file_reader
      @caching_file_reader ||= Scanners::Files::CachingFileReader.new
    end

    def used_key_names(strict: nil)
      (@used_key_names ||= {})[strict?(strict)] ||= used_tree(strict: strict).key_names
    end

    # whether the key is used in the source
    def used_key?(key)
      used_key_names(strict: true).include?(key)
    end

    # @return whether the key is potentially used in a code expression such as `t("category.#{ category_key }")`
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    # @param strict [Boolean, nil]
    # @return [Boolean]
    def strict?(strict)
      strict.nil? ? search_config[:strict] : strict
    end

    # keys in the source that end with a ., e.g. t("category.#{ cat.i18n_key }") or t("category." + category.key)
    def expr_key_re
      @expr_key_re ||= begin
        patterns = used_key_names(strict: false).select { |k| key_expression?(k) }.map { |k|
          pattern = key_match_pattern(k)
          # disallow patterns with no keys
          next if pattern =~ /\A(:\.)*:\z/
          pattern
        }.compact
        compile_key_pattern "{#{patterns * ','}}"
      end
    end
  end
end
