# coding: utf-8
require 'term/ansicolor'
require 'i18n/tasks/task_helpers'

module I18n
  module Tasks
    class BaseTask
      include Term::ANSIColor
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
          if grep_out = run_grep
            grep_out.split("\n").map {|r|
              key = r.match(/['"](.*?)['"]/)[1]
              # absolutize relative key:
              if key.start_with? '.'
                path = r.split(':')[0]
                # normalized path
                path = Pathname.new(File.expand_path path).relative_path_from(Pathname.new(Dir.pwd)).to_s
                # key prefix based on path
                prefix = path.gsub(%r(app/views/|(\.[^/]+)*$), '').tr('/', '.')
                "#{prefix}#{key}"
              else
                key
              end
            }.uniq.reject {|k| k !~ /^[\w.\#{}]+$/ }
          else
            []
          end
        end
      end

      def find_source_pattern_keys
        @source_pattern_keys ||= find_source_keys.select {|k| k =~ /\#{.*?}/ || k.ends_with?('.') }
      end

      def find_source_pattern_prefixes
        @source_pattern_prefixes ||= find_source_pattern_keys.map {|k| k.split(/\.?#/)[0] }
      end

      # traverse hash, yielding with full key and value
      def traverse(path = '', hash)
        q = [ [path, hash] ]
        until q.empty?
          path, value = q.pop
          if value.is_a?(Hash)
            value.each {|k,v| q << ["#{path}.#{k}", v] }
          else
            yield path[1..-1], value
          end
        end
      end

      def t(hash, key)
        key.split('.').inject(hash) {|r,seg| r[seg] if r }
      end

      def base_locale
        I18n.default_locale.to_s
      end

      def base
        @base ||= get_locale_data(base_locale)
      end

      def run_grep
        incl = grep_config[:include].blank? ? nil : "--include=#{grep_config[:include]}"
        excl = grep_config[:exclude].blank? ? nil : "--exclude=#{grep_config[:exclude]}"

        args = [
          'grep', '-HorI',
          incl, excl,
          %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]},
          *grep_config[:paths]
        ].compact

        run_command *args
      end

    end
  end
end
