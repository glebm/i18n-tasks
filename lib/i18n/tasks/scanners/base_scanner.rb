# coding: utf-8
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/scanners/relative_keys'

module I18n::Tasks::Scanners
  class BaseScanner
    include RelativeKeys
    include ::I18n::Tasks::KeyPatternMatching
    include ::I18n::Tasks::Logging

    attr_reader :config, :key_filter, :ignore_lines_res

    ALWAYS_EXCLUDE = %w(*.jpg *.png *.gif *.svg *.ico *.eot *.otf *.ttf *.woff *.woff2 *.pdf
                        *.css *.sass *.scss *.less *.yml *.json)

    def initialize(config = {})
      @config = config.dup.with_indifferent_access.tap do |conf|
        conf[:relative_roots] = %w(app/views app/controllers app/helpers app/presenters) if conf[:relative_roots].blank?
        conf[:paths]   = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude]) + ALWAYS_EXCLUDE
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
        @ignore_lines_res = conf[:ignore_lines].inject({}) { |h, (ext, re)| h.update(ext => Regexp.new(re)) }
        @key_filter = nil
      end
    end

    def exclude_line?(line, path)
      re = ignore_lines_res[File.extname(path)[1..-1]]
      re && re =~ line
    end

    def key_filter=(value)
      @key_filter         = value
      @key_filter_pattern = compile_key_pattern(value) if @key_filter
    end

    # @return [Array<{key,data:{source_occurrences:[]}}]
    def keys(opts = {})
      keys = traverse_files { |path|
        scan_file(path, opts)
      }.reduce(:+) || []
      keys.group_by(&:first).map { |key, key_loc|
        [key, data: {source_occurrences: key_loc.map { |(_k, attr)| attr[:data] }}]
      }
    end

    def read_file(path)
      result = nil
      File.open(path, 'rb', encoding: 'UTF-8') { |f| result = f.read }
      result
    end

    # @return [Array<Key>] keys found in file
    def scan_file(path, opts = {})
      raise 'Unimplemented'
    end

    # Run given block for every relevant file, according to config
    # @return [Array] Results of block calls
    def traverse_files
      result = []
      paths  = config[:paths].select { |p| File.exist?(p) }
      if paths.empty?
        log_warn "search.paths #{config[:paths].inspect} do not exist"
        return result
      end
      Find.find(*paths) do |path|
        is_dir   = File.directory?(path)
        hidden   = File.basename(path).start_with?('.')
        not_incl = config[:include] && !path_fnmatch_any?(path, config[:include])
        excl     = path_fnmatch_any?(path, config[:exclude])
        if is_dir || hidden || not_incl || excl
          Find.prune if is_dir && (hidden || excl)
        else
          result << yield(path)
        end
      end
      result
    end

    def with_key_filter(key_filter = nil)
      filter_was      = @key_filter
      self.key_filter = key_filter
      yield
    ensure
      self.key_filter = filter_was
    end

    protected

    def path_fnmatch_any?(path, globs)
      globs.any? { |glob| File.fnmatch(glob, path) }
    end

    def src_location(path, text, src_pos, position = true)
      data = {src_path: path}
      if position
        line_begin = text.rindex(/^/, src_pos - 1)
        line_end   = text.index(/.(?=\n|$)/, src_pos)
        data.merge! pos:      src_pos,
                    line_num: text[0..src_pos].count("\n") + 1,
                    line_pos: src_pos - line_begin + 1,
                    line:     text[line_begin..line_end]
      end
      data
    end

    # remove the leading colon and unwrap quotes from the key match
    def strip_literal(literal)
      key = literal
      key = key[1..-1] if ':' == key[0]
      key = key[1..-2] if %w(' ").include?(key[0])
      key
    end

    VALID_KEY_CHARS = /(?:[[:word:]]|[-.?!;À-ž])/
    VALID_KEY_RE_STRICT = /^#{VALID_KEY_CHARS}+$/
    VALID_KEY_RE = /^(#{VALID_KEY_CHARS}|[:\#{@}\[\]])+$/

    def valid_key?(key, strict = false)
      return false if @key_filter && @key_filter_pattern !~ key
      if strict
        key =~ VALID_KEY_RE_STRICT && !key.end_with?('.')
      else
        key =~ VALID_KEY_RE
      end
    end

    def relative_roots
      config[:relative_roots]
    end

  end
end
