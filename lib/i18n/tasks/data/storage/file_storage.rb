require 'i18n/tasks/data_traversal'
require 'i18n/tasks/key_pattern_matching'

module I18n::Tasks
  module Data
    module Storage
      module FileStorage

        def self.included(base)
          base.extend KlassMethods
        end

        include ::I18n::Tasks::DataTraversal
        include ::I18n::Tasks::KeyPatternMatching
        attr_reader :config

        DEFAULTS = {
            read:  ['config/locales/%{locale}.yml'],
            write: ['config/locales/%{locale}.yml']
        }.with_indifferent_access

        def initialize(config = {})
          self.config = config
        end

        def config=(config)
          opt          = DEFAULTS.deep_merge((config || {}).with_indifferent_access)
          @read        = opt[:read]
          @write       = opt[:write].map { |x| x.is_a?(String) ? ['*', x] : x }.map { |x|
            [compile_key_pattern(x[0]), x[1]]
          }
          @locale_data = {}
        end

        # get locale tree
        def get(locale)
          locale               = locale.to_s
          @locale_data[locale] ||= begin
            @read.map do |path|
              Dir.glob path % {locale: locale}
            end.flatten.map do |locale_file|
              load_file locale_file
            end.inject({}) do |hash, locale_data|
              hash.deep_merge! locale_data || {}
              hash
            end[locale.to_s] || {}
          end
        end

        alias [] get

        # set locale tree
        def set(locale, value_tree)
          locale = locale.to_s
          out    = {}
          traverse value_tree do |key, value|
            route     = @write.detect { |route| route[0] =~ key }
            key_match = $~
            path      = route[1] % {locale: locale}
            path.gsub!(/[\\]\d+/) { |m| key_match[m[1..-1].to_i] }
            (out[path] ||= []) << [key, value]
          end
          out.each do |path, data|
            tree = {locale => list_to_tree(data)}
            write_tree(path, tree)
          end
          @locale_data[locale] = nil
        end

        alias []= set

        def reload
          @locale_data = {}
        end

        protected

        def load_file(file)
          adapter_for(file).parse ::File.read(file)
        end

        def write_tree(path, tree)
          ::File.open(path, 'w') { |f| f.write(adapter_for(path).dump(tree)) }
        end

        def adapter_for(file)
          self.class.adapter_for(file)
        end

        module KlassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(pattern, adapter)
            (@fn_patterns ||= {})[pattern] = adapter
          end

          def adapter_for(path)
            @fn_patterns.detect { |pattern, adapter| ::File.fnmatch(pattern, path) }[1] or
                raise "Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}"
          end
        end
      end
    end
  end
end
