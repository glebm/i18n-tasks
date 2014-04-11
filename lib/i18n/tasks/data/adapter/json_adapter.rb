require 'json'

module I18n::Tasks
  module Data
    module Adapter
      module JsonAdapter
        extend self

        # @return [Hash] locale tree
        def parse(str, opts)
          JSON.parse(str, opts || {})
        end

        # @return [String]
        def dump(tree, opts)
          JSON.generate(tree, opts || {})
        end

      end
    end
  end
end
