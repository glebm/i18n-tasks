# coding: utf-8
require 'yaml'
module I18n::Tasks
  module Data
    module Adapter
      module YamlAdapter
        extend self

        # @return [Hash] locale tree
        def parse(str, options)
          YAML.load(str, options || {})
        end

        # @return [String]
        def dump(tree, options)
          tree.to_yaml(options || {})
        end

      end
    end
  end
end
