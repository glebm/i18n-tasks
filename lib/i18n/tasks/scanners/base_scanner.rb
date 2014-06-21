# coding: utf-8
require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/relative_keys'
module I18n::Tasks::Scanners
  class BaseScanner
    include ::I18n::Tasks::RelativeKeys
    include ::I18n::Tasks::KeyPatternMatching
    include ::I18n::Tasks::Logging

    attr_reader :config, :key_filter, :record_src_loc

    def initialize(config = {})
      @config         = config.dup.with_indifferent_access.tap do |conf|
        conf[:paths]   = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        if conf.key?(:exclude)
          conf[:exclude] = Array(conf[:exclude])
        else
          # exclude common binary extensions by default (images and fonts)
          conf[:exclude] = %w(*.jpg *.png *.gif *.svg *.ico *.eot *.ttf *.woff *.pdf)
        end
      end
      @record_src_loc = false
    end

    def key_filter=(value)
      @key_filter         = value
      @key_filter_pattern = compile_key_pattern(value) if @key_filter
    end

    # @return [Array] keys used in source, absolutized and unique
    def keys
      @keys ||= (traverse_files { |path| scan_file(path) }.reduce(:+) || []).uniq(&:first)
    end

    # @return [Array<{key,usages}]
    def keys_with_source_locations
      recording_source_locations do
        keys = traverse_files { |path|
          scan_file(path)
        }.reduce(:+) || []
        keys.group_by(&:first).map { |key, key_loc|
          [key, data: {source_locations: key_loc.map { |(k, attr)| attr[:data] }}]
        }
      end
    end

    def read_file(path)
      result = nil
      File.open(path, 'rb') { |f| result = f.read }
      result
    end

    # @return [Array<Key>] keys found in file
    def scan_file(path, *args)
      raise 'Unimplemented'
    end

    # Run given block for every relevant file, according to config
    # @return [Array] Results of block calls
    def traverse_files
      result = []
      paths  = config[:paths].select { |p| File.exists?(p) }
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

    def recording_source_locations
      was             = @record_src_loc
      @record_src_loc = true
      yield
    ensure
      @record_src_loc = was
    end

    protected

    def path_fnmatch_any?(path, globs)
      globs.any? { |glob| File.fnmatch(glob, path) }
    end

    def src_location(path, text, src_pos)
      src = {path: path}
      if @record_src_loc
        src.merge!(src_text_location(text, src_pos))
      end
      src
    end

    def src_text_location(text, src_pos)
      line_begin = text.rindex(/^/, src_pos - 1)
      line_end   = text.index(/.(?=\n|$)/, src_pos)
      {
          pos:      src_pos,
          line_num: text[0..src_pos].count("\n") + 1,
          line_pos: src_pos - line_begin + 1,
          line:     text[line_begin..line_end]
      }
    end

    # remove the leading colon and unwrap quotes from the key match
    def strip_literal(literal)
      key = literal
      key = key[1..-1] if ':' == key[0]
      key = key[1..-2] if %w(' ").include?(key[0])
      key
    end

    VALID_KEY_RE = /^[-\w.\#{}]+$/

    def valid_key?(key)
      key =~ VALID_KEY_RE && !(@key_filter && @key_filter_pattern !~ key)
    end

    def relative_roots
      config[:relative_roots]
    end

  end
end
