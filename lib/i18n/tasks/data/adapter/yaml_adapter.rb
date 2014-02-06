require 'yaml'
module I18n::Tasks
  module Data
    module Adapter
      module YamlAdapter
        extend self

        # @return [Hash] locale tree
        def parse(str)
          YAML.load(str)
        end

        # @return [String]
        def dump(tree)
          tree.to_yaml
        end

      end
    end
  end
end
