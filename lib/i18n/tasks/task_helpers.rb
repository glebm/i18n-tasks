module I18n
  module Tasks
    module TaskHelpers
      def trn_path(locale)
        "config/locales/#{locale}.yml"
      end

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
        @base ||= YAML.load_file trn_path(base_locale)
      end
    end
  end
end
