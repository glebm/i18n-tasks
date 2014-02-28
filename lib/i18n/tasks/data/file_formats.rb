module I18n
  module Tasks
    module Data
      module FileFormats
        def self.included(base)
          base.extend ClassMethods
        end

        delegate :adapter_for, to: :class

        protected

        def load_file(file)
          adapter_for(file).parse(
              ::File.read(file)
          )
        end

        def write_tree(path, tree)
          ::File.open(path, 'w') { |f|
            f.write(adapter_for(path).dump(tree.to_hash))
          }
        end

        module ClassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(pattern, adapter)
            (@fn_patterns ||= {})[pattern] = adapter
          end

          def adapter_for(path)
            @fn_patterns.detect { |pattern, adapter|
              ::File.fnmatch(pattern, path)
            }[1] or raise "Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}"
          end
        end
      end
    end
  end
end
