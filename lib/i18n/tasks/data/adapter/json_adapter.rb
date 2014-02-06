require 'json'

module I18n::Tasks
  module Data
    module Adapter
      module JsonAdapter
        extend self

        # @return [Hash] locale tree
        def parse(str)
          JSON.parse(str)
        end

        # @return [String]
        def dump(tree)
          JSON.generate(tree)
        end

      end
    end
  end
end
