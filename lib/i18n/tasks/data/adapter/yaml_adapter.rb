# frozen_string_literal: true
require 'yaml'
module I18n::Tasks
  module Data
    module Adapter
      module YamlAdapter
        class << self
          # @return [Hash] locale tree
          def parse(str, options)
            if YAML.method(:load).arity.abs == 2
              YAML.load(str, options || {})
            else
              # older jruby and rbx 2.2.7 do not accept options
              YAML.load(str)
            end
          end

          # @return [String]
          def dump(tree, options)
            tree.to_yaml(options || {})
          end
        end
      end
    end
  end
end
