# coding: utf-8
require 'json'

module I18n::Tasks
  module Data
    module Adapter
      module JsonAdapter
        extend self

        # @return [Hash] locale tree
        def parse(str, opts)
          JSON.parse(str, parse_opts(opts))
        end

        # @return [String]
        def dump(tree, opts)
          JSON.generate(tree, parse_opts(opts))
        end

        private
        def parse_opts(opts)
          opts.try(:symbolize_keys) || {}
        end
      end
    end
  end
end
