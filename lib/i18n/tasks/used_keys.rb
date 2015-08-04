require 'find'
require 'i18n/tasks/scanners/pattern_with_scope_scanner'
require 'i18n/tasks/scanners/scanner_multiplexer'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'
require 'i18n/tasks/scanners/files/caching_file_reader'

module I18n::Tasks
  module UsedKeys
    STRICT_DEFAULT = false

    # Find all keys in the source and return a forest with the keys in absolute form and their occurrences.
    #
    # @param key_filter [String] only return keys matching this pattern.
    # @param strict [Boolean] if true, dynamic keys are excluded (e.g. `t("category.#{category.key}")`)
    # @return [Data::Tree::Siblings]
    def used_tree(key_filter: nil, strict: nil)
      keys = scanner(strict: strict).keys
      if key_filter
        key_filter_re = compile_key_pattern(key_filter)
        keys.select! { |k| k.key =~ key_filter_re }
      end
      Data::Tree::Node.new(
          key:      'used',
          data:     {key_filter: key_filter},
          children: Data::Tree::Siblings.from_key_occurrences(keys)
      ).to_siblings
    end

    def scanner(strict: nil)
      (@scanner ||= {})[strict || STRICT_DEFAULT] ||= begin
        config = search_config
        config[:strict] = strict unless strict.nil?
        Scanners::ScannerMultiplexer.new(
            scanners: search_config[:scanners].map { |scanner_class_args|
              class_name, args = scanner_class_args
              ActiveSupport::Inflector.constantize(class_name).new(
                  config:               search_config.deep_merge(args || {}),
                  file_finder_provider: caching_file_finder_provider,
                  file_reader:          caching_file_reader)
            })
      end
    end

    def search_config
      @search_config ||= apply_default_scanner_config((config[:search] || {}).dup.deep_symbolize_keys)
    end

    def apply_default_scanner_config(conf)
      conf[:strict] = false unless conf.key?(:strict)
      if conf[:scanner]
        warn_deprecated 'search.scanner is now search.scanners, an array of [ScannerClass, options]'
        conf[:scanners] = [[conf.delete(:scanner)]]
      end
      conf[:scanners] ||= [['::I18n::Tasks::Scanners::PatternWithScopeScanner']]
      if conf[:relative_roots].blank?
        conf[:relative_roots] = %w(app/controllers app/helpers app/mailers app/presenters app/views)
      end
      conf[:paths]   = %w(app/) if conf[:paths].blank?
      conf[:include] = Array(conf[:include]) if conf[:include].present?
      conf[:exclude] = Array(conf[:exclude]) + %w(
          *.jpg *.png *.gif *.svg *.ico *.eot *.otf *.ttf *.woff *.woff2 *.pdf *.css *.sass *.scss *.less *.yml *.json)
      # Regexps for lines to ignore per extension
      if conf[:ignore_lines] && !conf[:ignore_lines].is_a?(Hash)
        warn_deprecated "search.ignore_lines must be a Hash, found #{conf[:ignore_lines].class.name}"
        conf[:ignore_lines] = nil
      end
      conf[:ignore_lines] ||= {
          'rb'     => %q(^\s*#(?!\si18n-tasks-use)),
          'opal'   => %q(^\s*#(?!\si18n-tasks-use)),
          'haml'   => %q(^\s*-\s*#(?!\si18n-tasks-use)),
          'slim'   => %q(^\s*(?:-#|/)(?!\si18n-tasks-use)),
          'coffee' => %q(^\s*#(?!\si18n-tasks-use)),
          'erb'    => %q(^\s*<%\s*#(?!\si18n-tasks-use)),
      }
      conf
    end


    def caching_file_finder_provider
      @caching_file_finder_provider ||= Scanners::Files::CachingFileFinderProvider.new
    end

    def caching_file_reader
      @caching_file_reader ||= Scanners::Files::CachingFileReader.new
    end

    def used_key_names(strict = false)
      if strict
        @used_key_names ||= used_tree(strict: true).key_names
      else
        @used_key_names ||= used_tree.key_names
      end
    end

    # whether the key is used in the source
    def used_key?(key, strict = false)
      used_key_names(strict).include?(key)
    end

    # @return whether the key is potentially used in a code expression such as:
    #   t("category.#{category_key}")
    def used_in_expr?(key)
      !!(key =~ expr_key_re)
    end

    # keys in the source that end with a ., e.g. t("category.#{cat.i18n_key}") or t("category." + category.key)
    def expr_key_re
      @expr_key_re ||= begin
        patterns = used_key_names.select { |k| key_expression?(k) }.map { |k|
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
