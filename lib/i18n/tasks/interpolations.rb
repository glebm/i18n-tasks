# frozen_string_literal: true

module I18n::Tasks
  module Interpolations
    class << self
      attr_accessor :variable_regex
    end
    @variable_regex = /(?<!%)%{[^}]+}/

    def inconsistent_interpolations(locales: nil, base_locale: nil) # rubocop:disable Metrics/AbcSize
      locales ||= self.locales
      base_locale ||= self.base_locale
      result = empty_forest
      variable_regex = I18n::Tasks::Interpolations.variable_regex

      plural_keys = Set.new
      plural_nodes(data[base_locale]) do |node|
        group_key = node.full_key(root: false)
        node.children.each { |form| plural_keys << "#{group_key}.#{form.key}" }
        next if ignore_key?(group_key, :inconsistent_interpolations)

        (locales - [base_locale]).each do |current_locale|
          inconsistent_plural_forms(node, data[current_locale].first.children[group_key], variable_regex).each do |form|
            next if ignore_key?("#{group_key}.#{form.key}", :inconsistent_interpolations)

            result.merge!(form.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
          end
        end
      end

      data[base_locale].key_values.each do |key, value|
        next if plural_keys.include?(key)
        next if !value.is_a?(String) || ignore_key?(key, :inconsistent_interpolations)

        base_vars = Set.new(value.scan(variable_regex))
        (locales - [base_locale]).each do |current_locale|
          node = data[current_locale].first.children[key]
          next unless node&.value.is_a?(String)

          if base_vars != Set.new(node.value.scan(variable_regex))
            result.merge!(node.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
          end
        end
      end

      result.each { |root| root.data[:type] = :inconsistent_interpolations }
      result
    end

    # Plural forms are compared as a group, because locales have different forms than the base: Russian has `few`
    # and `many`, and its `one` also covers 21, 31, ..., so it needs `%{count}` even when the English `one` omits it.
    # A translated form may only use variables from the base group. It must keep the variables of the same base form,
    # or of `other` for a form the base does not have. A `zero`, `one` or `two` form the base lacks often spells the
    # number out (Arabic and Hebrew duals), so it is only checked for unknown variables.
    SPELLED_OUT_FORMS = %w[zero one two].freeze

    def inconsistent_plural_forms(base_node, node, variable_regex)
      return [] unless node&.children? && plural_forms?(node.children)

      scan = ->(form) { form.value.is_a?(String) ? Set.new(form.value.scan(variable_regex)) : Set.new }
      base_forms = base_node.children.to_a.to_h { |form| [form.key, scan.call(form)] }
      base_vars = base_forms.values.reduce(Set.new, :|)
      node.children.select do |form|
        next false unless form.value.is_a?(String)

        vars = scan.call(form)
        required = base_forms[form.key] || required_from_other(base_forms["other"] || base_vars, form.key)
        !vars.subset?(base_vars) || !required.subset?(vars)
      end
    end

    def required_from_other(other_vars, form_key)
      SPELLED_OUT_FORMS.include?(form_key) ? Set.new : other_vars
    end

    def reserved_interpolations(locales: nil)
      locales ||= self.locales
      result = empty_forest

      locales.each do |current_locale|
        data[current_locale].key_values.each do |key, value|
          next unless value.is_a?(String)

          reserved_variables = value.scan(::I18n.reserved_keys_pattern).flatten
          next if reserved_variables.empty?

          result.merge!(data[current_locale].first.children[key].walk_to_root.reduce(nil) do |c, p|
            [p.derive(children: c, value: reserved_variables)]
          end)
        end
      end
      result.each { |root| root.data[:type] = :inconsistent_interpolations }
      result
    end
  end
end
