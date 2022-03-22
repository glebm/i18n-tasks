# frozen_string_literal: true

require 'yaml'
module I18n::Tasks
  module Data
    module Adapter
      module YamlAdapter
        EMOJI_REGEX = /\\u[\da-f]{8}/i

        class << self
          # @return [Hash] locale tree
          def parse(str, options)
            if YAML.method(:load).arity.abs == 2
              YAML.safe_load(str, **(options || {}), permitted_classes: [Symbol], aliases: true)
            else
              # older jruby and rbx 2.2.7 do not accept options
              YAML.load(str)
            end
          end

          # @return [String]
          def dump(tree, options)
            restore_emojis(tree.to_yaml(options || {}))
          end

          # @return [String]
          def restore_emojis(yaml)
            yaml.gsub(EMOJI_REGEX) { |m| [m[-8..].to_i(16)].pack("U") }
          end
        end
      end
    end
  end
end
