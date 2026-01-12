# frozen_string_literal: true

require "yaml"
module I18n::Tasks
  module Data
    module Adapter
      module YamlAdapter
        EMOJI_REGEX = /\\u[\da-f]{8}/i
        TRAILING_SPACE_REGEX = / $/
        SINGLE_QUOTED_VALUE = /^(\s*\S.*?):\s*'((?:[^']|'')*)'(\s*)$/

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
            options = (options || {}).dup
            quote_style = options.delete(:quote)&.to_s
            apply_quote_style(strip_trailing_spaces(restore_emojis(tree.to_yaml(options))), quote_style)
          end

          # @return [String]
          def restore_emojis(yaml)
            yaml.gsub(EMOJI_REGEX) { |m| [m[-8..].to_i(16)].pack("U") }
          end

          # @return [String]
          def strip_trailing_spaces(yaml)
            yaml.gsub(TRAILING_SPACE_REGEX, "")
          end

          private

          def apply_quote_style(yaml, style)
            return yaml unless %w[double prettier].include?(style)

            yaml.gsub(SINGLE_QUOTED_VALUE) do |match|
              key_part, value, trailing = Regexp.last_match[1], Regexp.last_match[2], Regexp.last_match[3]
              unescaped = value.gsub("''", "'")

              case style
              when "double"
                double_quote(key_part, unescaped, trailing)
              when "prettier"
                prettier_quote(key_part, unescaped, value, trailing, match)
              else
                match
              end
            end
          end

          def double_quote(key_part, value, trailing)
            escaped = value.gsub("\\", "\\\\").gsub('"', '\\"')
            "#{key_part}: \"#{escaped}\"#{trailing}"
          end

          def prettier_quote(key_part, unescaped, original_single, trailing, match)
            single_escapes = original_single.scan("''").size
            double_escapes = unescaped.count('"') + unescaped.count("\\") # need to escape these in double quotes

            if double_escapes <= single_escapes
              double_quote(key_part, unescaped, trailing)
            else
              match
            end
          end
        end
      end
    end
  end
end
