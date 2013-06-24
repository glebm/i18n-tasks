require 'open3'

module I18n
  module Tasks
    module TaskHelpers
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
