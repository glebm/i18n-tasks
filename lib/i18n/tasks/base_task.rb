# coding: utf-8
require 'term/ansicolor'
require 'i18n/tasks/task_helpers'

module I18n
  module Tasks
    class BaseTask
      include TaskHelpers

      # locale data hash, with locale name as root
      def get_locale_data(locale)
        (@locale_data ||= {})[locale] ||= I18n::Tasks.get_locale_data.call(locale)
      end

      # main locale file path (for writing to)
      def locale_file_path(locale)
        "config/locales/#{locale}.yml"
      end

      # find all keys in the source (relative keys are returned in absolutized)
      def find_source_keys
        @source_keys ||= begin
          if (grep_out = run_grep)
            grep_out.split("\n").map { |r|
              key = r.match(/['"](.*?)['"]/)[1]
              if key.start_with? '.'
                absolutize_key key, r.split(':')[0]
              else
                key
              end
            }.uniq.reject { |k| k !~ /^[\w.\#{}]+$/ }
          else
            []
          end
        end
      end

      # whether the key is used in the source
      def used_key?(key)
        @used_keys ||= find_source_keys.to_set
        @used_keys.include?(key)
      end

      # whether to ignore the key. ignore_type one of :missing, :eq_base, :blank, :unused.
      # will apply global ignore rules as well
      def ignore_key?(key, ignore_type, locale = nil)
        key =~ ignore_pattern(ignore_type, locale)
      end

      # dynamically generated keys in the source, e.g t("category.#{category_key}")
      def pattern_key?(key)
        @pattern_keys_re ||= compile_start_with_re(find_source_pattern_prefixes)
        key =~ @pattern_keys_re
      end

      def key_has_value?(key, locale = base_locale)
        t(get_locale_data(locale)[locale], key).present?
      end

      # traverse hash, yielding with full key and value
      def traverse(path = '', hash)
        q = [ [path, hash] ]
        until q.empty?
          path, value = q.pop
          if value.is_a?(Hash)
            value.each { |k,v| q << ["#{path}.#{k}", v] }
          else
            yield path[1..-1], value
          end
        end
      end

      def t(hash, key)
        key.split('.').inject(hash) { |r,seg| r[seg] if r }
      end

      def absolutize_key(key, path)
        # normalized path
        path = Pathname.new(File.expand_path path).relative_path_from(Pathname.new(Dir.pwd)).to_s
        # key prefix based on path
        prefix = path.gsub(%r(app/views/|(\.[^/]+)*$), '').tr('/', '.')
        "#{prefix}#{key}"
      end

      def find_source_pattern_keys
        @source_pattern_keys ||= find_source_keys.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }
      end

      def find_source_pattern_prefixes
        @source_pattern_prefixes ||= find_source_pattern_keys.map { |k| k.split(/\.?#/)[0] }
      end

      def base_locale
        I18n.default_locale.to_s
      end

      def base_locale_data
        get_locale_data(base_locale)[base_locale]
      end

      def run_grep
        args = ['grep', '-HoRI']
        [:include, :exclude].each do |opt|
          next unless (val = grep_config[opt]).present?
          args += Array(val).map { |v| "--#{opt}=#{v}" }
        end
        args += [ %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, *grep_config[:paths]]
        args.compact!
        run_command *args
      end

    end
  end
end
