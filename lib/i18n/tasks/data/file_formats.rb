# coding: utf-8
require 'fileutils'

module I18n
  module Tasks
    module Data
      module FileFormats
        def self.included(base)
          base.extend ClassMethods
        end

        def adapter_dump(tree, format)
          adapter_op :dump, format, tree, write_config(format)
        end

        def adapter_parse(tree, format)
          adapter_op :parse, format, tree, read_config(format)
        end

        def adapter_op(op, format, tree, config)
          self.class.adapter_by_name(format).send(op, tree, config)
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
          adapter_parse ::File.read(path), self.class.adapter_name_for_path(path)
        end

        def write_tree(path, tree)
          payload = adapter_dump(tree.to_hash(true), self.class.adapter_name_for_path(path))
          unless File.file?(path) && payload == load_file(path)
            ::FileUtils.mkpath(File.dirname path)
            ::File.open(path, 'w') { |f| f.write payload }
          end
        end

        module ClassMethods
          # @param pattern [String] File.fnmatch pattern
          # @param adapter [responds to parse(string)->hash and dump(hash)->string]
          def register_adapter(name, pattern, adapter)
            (@fn_patterns ||= []) << [name, pattern, adapter]
          end

          def adapter_name_for_path(path)
            @fn_patterns.detect { |(_name, pattern, _adapter)|
              ::File.fnmatch(pattern, path)
            }.try(:first) or raise CommandError.new("Adapter not found for #{path}. Registered adapters: #{@fn_patterns.inspect}")
          end

          def adapter_names
            @fn_patterns.map(&:first)
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
