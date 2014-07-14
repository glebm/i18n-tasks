# coding: utf-8
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

        def adapter_by_name(path)
          self.class.adapter_by_name(path)
        end

        def adapter_dump(tree, adapter_info)
          adapter_name, adapter_pattern, adapter = adapter_info
          adapter_options = (config[adapter_name] || {})[:write]
          adapter.dump(tree, adapter_options)
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
            f.write(adapter_dump(tree.to_hash, adapter_for(path)))
          }
        end

        module ClassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(name, pattern, adapter)
            (@fn_patterns ||= []) << [name, pattern, adapter]
          end

          def adapter_for(path)
            @fn_patterns.detect { |(_name, pattern, _adapter)|
              ::File.fnmatch(pattern, path)
            } or raise CommandError.new("Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}")
          end

          def adapter_by_name(name)
            name = name.to_s
            @fn_patterns.detect { |(adapter_name, _pattern, _adapter)|
              adapter_name.to_s == name
            } or raise CommandError.new("Adapter with name #{name.inspect} not found. Registered adapters: #{@fn_patterns.inspect}")
          end
        end
      end
    end
  end
end
