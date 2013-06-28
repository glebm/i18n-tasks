require 'open3'
require 'term/ansicolor'

module I18n
  module Tasks
    module TaskHelpers
      include Term::ANSIColor
      def run_command(*args)
        _in, out, _err = Open3.popen3(*args)
        out.gets nil
      end

      # locale data hash, with locale name as root
      def get_locale_data(locale)
        # todo multiple files, configuration option
        YAML.load_file "config/locales/#{locale}.yml"
      end

      # main locale file path (for writing to)
      def locale_file_path(locale)
        "config/locales/#{locale}.yml"
      end

      # find all keys in the source
      def find_source_keys
        @source_keys ||= begin
          grep_out = run_command 'grep', '-horI', %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, 'app/'
          used_keys = grep_out.split("\n").map { |r| r.match(/['"](.*?)['"]/)[1] }.uniq.to_set
        end
      end

      def find_source_pattern_keys
        find_source_keys.select { |k| k =~ /\#{.*?}/ || k.ends_with?('.') }
      end

      def find_source_pattern_prefixes
        find_source_pattern_keys.map { |k| k.split(/\.?#/)[0] }
      end

      # traverse hash, yielding with full key and value
      def traverse(path = '', hash, &block)
        hash.each do |k, v|
          if v.is_a?(Hash)
            traverse("#{path}.#{k}", v, &block)
          else
            block.call("#{path}.#{k}"[1..-1], v)
          end
        end
      end

      def t(hash, key)
        key.split('.').inject(hash) { |r, seg| r.try(:[], seg) }
      end

      def base_locale
        I18n.default_locale.to_s
      end

      def base
        @base ||= get_locale_data(base_locale)
      end
    end
  end
end
