# frozen_string_literal: true

require 'i18n/tasks/key_pattern_matching'
require 'i18n/tasks/data/tree/node'

module I18n::Tasks
  module Data::Router
    # Route based on source file path
    class IsolatingRouter
      include ::I18n::Tasks::KeyPatternMatching

      attr_reader :config_read_patterns, :base_locale

      def initialize(_adapter, data_config)
        @base_locale = data_config[:base_locale]
        @config_read_patterns = Array.wrap(data_config[:read])
      end

      # Route keys to destinations
      # @param forest [I18n::Tasks::Data::Tree::Siblings] forest roots are locales.
      # @yieldparam [String] dest_path
      # @yieldparam [I18n::Tasks::Data::Tree::Siblings] tree_slice
      # @return [Hash] mapping of destination => [ [key, value], ... ]
      def route(locale, forest, &block)
        return to_enum(:route, locale, forest) unless block

        locale = locale.to_s
        out = {}

        forest.keys do |key_namespaced_with_source_path, _node|
          source_path, key = key_namespaced_with_source_path.match(/\A<([^>]*)>\.(.*)/).captures
          target_path = alternate_path_for(source_path, locale)
          next unless source_path && key && target_path

          (out[target_path] ||= Set.new) << "#{locale}.#{key}"
        end

        out.each do |target_path, keys|
          file_namespace_subtree = I18n::Tasks::Data::Tree::Siblings.new(
            nodes: forest.get("#{locale}.<#{alternate_path_for(target_path, base_locale)}>")
          )
          file_namespace_subtree.set_root_key!(locale)

          block.yield(
            target_path,
            file_namespace_subtree.select_keys { |key, _| keys.include?(key) }
          )
        end
      end

      def alternate_path_for(source_path, locale)
        source_path = source_path.dup

        config_read_patterns.each do |pattern|
          regexp = Glob.new(format(pattern, locale: '(*)')).to_regexp
          next unless source_path.match?(regexp)

          source_path.match(regexp) do |match_data|
            (1..match_data.size - 1).reverse_each do |capture_index|
              capture_begin, capture_end = match_data.offset(capture_index)
              source_path.slice!(Range.new(capture_begin, capture_end, true))
              source_path.insert(capture_begin, locale.to_s)
            end
          end

          return source_path
        end

        nil
      end

      # based on https://github.com/alexch/rerun/blob/36f2d237985b670752abbe4a7f6814893cdde96f/lib/rerun/glob.rb
      class Glob
        NO_LEADING_DOT = '(?=[^\.])'
        START_OF_FILENAME = '(?:\A|\/)'
        END_OF_STRING = '\z'

        def initialize(pattern)
          @pattern = pattern
        end

        def to_regexp_string # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
          chars = smoosh(@pattern.chars)

          curlies = 0
          escaping = false

          string = chars.map do |char|
            if escaping
              escaping = false
              next char
            end

            case char
            when '**' then '(?:[^/]+/)*'
            when '*' then '.*'
            when '?' then '.'
            when '.' then '\.'
            when '{'
              curlies += 1
              '('
            when '}'
              if curlies.positive?
                curlies -= 1
                ')'
              else
                char
              end
            when ','
              if curlies.positive?
                '|'
              else
                char
              end
            when '\\'
              escaping = true
              '\\'
            else char
            end
          end.join

          START_OF_FILENAME + string + END_OF_STRING
        end

        def to_regexp
          Regexp.new(to_regexp_string)
        end

        def smoosh(chars)
          out = []
          until chars.empty?
            char = chars.shift
            if char == '*' && chars.first == '*'
              chars.shift
              chars.shift if chars.first == '/'
              out.push('**')
            else
              out.push(char)
            end
          end
          out
        end
      end
    end
  end
end
