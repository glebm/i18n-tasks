# frozen_string_literal: true

module I18n::Tasks
  module Interpolations
    class << self
      attr_accessor :variable_regex, :tag_pairs, :tag_with_localized_value_regex
    end
    @variable_regex = /(?<!%)%\{[^}]+\}|\{\{.*?\}\}|\{%.*?%\}/.freeze
    @tag_pairs = [
      ['{{', '}}'],
      ['%{', '}'],
      ['{%', '%}']
    ].freeze
    @tag_with_localized_value_regex = /\{\{\s?(("[^"]+")|('[^']+'))\s?\|.*?\}\}/

    def inconsistent_interpolations(locales: nil, base_locale: nil) # rubocop:disable Metrics/AbcSize
      locales ||= self.locales
      base_locale ||= self.base_locale
      result = empty_forest

      data[base_locale].key_values.each do |key, value|
        next if !value.is_a?(String) || ignore_key?(key, :inconsistent_interpolations)

        base_vars = get_normalized_variables_set(value)
        (locales - [base_locale]).each do |current_locale|
          node = data[current_locale].first.children[key]
          next unless node&.value.is_a?(String)

          if base_vars != get_normalized_variables_set(node.value)
            result.merge!(node.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
          end
        end
      end

      result.merge!(unrestored_interpolations(locales: locales))
      result.each { |root| root.data[:type] = :inconsistent_interpolations }
      result
    end

    def unrestored_interpolations(locales: nil)
      locales ||= self.locales
      result = empty_forest

      locales.each do |locale|
        data[locale].key_values.each do |key, value|
          next unless value.is_a?(String)
          next unless value.include?('!!!!!')

          node = Data::Tree::Node.new(key: key, value: value)
          result.set(key, node)
        end
      end
      result
    end

    def get_normalized_variables_set(string)
      Set.new(string.scan(I18n::Tasks::Interpolations.variable_regex).map { |variable| normalize(variable) })
    end

    def normalize(variable)
      normalized = nil
      if (match = variable.match(I18n::Tasks::Interpolations.tag_with_localized_value_regex))
        variable = variable.sub(match[1], 'localized input')
      end
      I18n::Tasks::Interpolations.tag_pairs.each do |start, end_|
        next unless variable.start_with?(start)

        normalized = variable.delete_prefix(start).delete_suffix(end_).strip
        normalized = start + normalized + end_
        break
      end

      fail 'No start/end tag pair detected' if normalized.nil?

      normalized
    end
  end
end
