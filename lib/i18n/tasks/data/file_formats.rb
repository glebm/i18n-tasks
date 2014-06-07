require 'fileutils'

module I18n
  module Tasks
    module Data
      module FileFormats
        def self.included(base)
          base.extend ClassMethods
        end

        def adapter_for(path)
          self.class.adapter_for(path)
        end

        protected

        def load_file(path)
          adapter_name, adapter_pattern, adapter = adapter_for(path)
          adapter_options = (config[adapter_name] || {})[:read]
          adapter.parse(::File.read(path), adapter_options)
        end

        def write_tree(path, tree)
          ::FileUtils.mkpath(File.dirname path)
          ::File.open(path, 'w') { |f|
            adapter_name, adapter_pattern, adapter = adapter_for(path)
            adapter_options = (config[adapter_name] || {})[:write]
            f.write(adapter.dump(tree.to_hash, adapter_options))
          }
        end

        module ClassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(name, pattern, adapter)
            (@fn_patterns ||= []) << [name, pattern, adapter]
          end

          def adapter_for(path)
            @fn_patterns.detect { |(name, pattern, adapter)|
              ::File.fnmatch(pattern, path)
            } or raise CommandError.new("Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}")
          end
        end
      end
    end
  end
end
