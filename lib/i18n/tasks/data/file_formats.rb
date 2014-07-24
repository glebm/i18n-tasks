# coding: utf-8
require 'fileutils'

module I18n
  module Tasks
    module Data
      module FileFormats
        def self.included(base)
          base.extend ClassMethods
        end

        delegate :adapter_for_path, :adapter_by_name, :adapter_name, :adapter_names, to: :class

        def adapter_dump(tree, format)
          adapter_op :dump, format, tree, write_config(format)
        end

        def adapter_parse(tree, format)
          adapter_op :parse, format, tree, read_config(format)
        end

        def adapter_op(op, format, tree, config)
          adapter_by_name(format).send(op, tree, config)
        rescue Exception => e
          raise CommandError.new("#{format} #{op} error: #{e.message}")
        end

        protected

        def write_config(format)
          (config[format] || {})[:write]
        end

        def read_config(format)
          (config[format] || {})[:read]
        end

        def load_file(path)
          adapter = adapter_for_path(path)
          adapter.parse ::File.read(path), read_config(adapter_name(adapter))
        end

        def write_tree(path, tree)
          ::FileUtils.mkpath(File.dirname path)
          ::File.open(path, 'w') { |f|
            f.write(adapter_dump(tree.to_hash, adapter_name(adapter_for_path(path))))
          }
        end

        module ClassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(name, pattern, adapter)
            (@fn_patterns ||= []) << [name, pattern, adapter]
          end

          def adapter_for_path(path)
            @fn_patterns.detect { |(_name, pattern, _adapter)|
              ::File.fnmatch(pattern, path)
            }.try(:last) or raise CommandError.new("Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}")
          end

          def adapter_names
            @fn_patterns.map(&:first)
          end

          def adapter_name(adapter)
            @fn_patterns.detect { |(adapter_name, _pattern, registered_adapter)|
              registered_adapter == adapter
            }.try(:first) or raise CommandError.new("Adapter #{adapter.inspect} is not registered. Registered adapters: #{@fn_patterns.inspect}")
          end

          def adapter_by_name(name)
            name = name.to_s
            @fn_patterns.detect { |(adapter_name, _pattern, _adapter)|
              adapter_name.to_s == name
            }.try(:last) or raise CommandError.new("Adapter with name #{name.inspect} not found. Registered adapters: #{@fn_patterns.inspect}")
          end
        end
      end
    end
  end
end
