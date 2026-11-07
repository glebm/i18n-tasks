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
      plural_keys = Set.new
      plural_nodes(data[base_locale]) do |base_node|
        next unless base_node.parent?

        group_key = base_node.full_key(root: false)
        base_node.children.each { |form| plural_keys << "#{group_key}.#{form.key}" }
        next if ignore_key?(group_key, :inconsistent_interpolations)

        (locales - [base_locale]).each do |current_locale|
          node = data[current_locale].first.children[group_key]
          inconsistent_plural_forms(current_locale, base_node, node).each do |form|
            next if ignore_key?("#{group_key}.#{form.key}", :inconsistent_interpolations)

            result.merge!(form.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
          end
        end
      end

      data[base_locale].key_values.each do |key, value|
        next if plural_keys.include?(key)
        next if !value.is_a?(String) || ignore_key?(key, :inconsistent_interpolations)

        base_vars = interpolation_variables(value)
        (locales - [base_locale]).each do |current_locale|
          node = data[current_locale].first.children[key]
          next unless node&.value.is_a?(String)

          if base_vars != interpolation_variables(node.value)
            result.merge!(node.walk_to_root.reduce(nil) { |c, p| [p.derive(children: c)] })
          end
        end
      end

      result.each { |root| root.data[:type] = :inconsistent_interpolations }
      result
    end

    COUNT_VARIABLE = "%{count}"
    # The forms that are used for at most one count when the locale has no plural rule in rails-i18n.
    SINGLE_COUNT_PLURAL_FORMS = %w[zero one two 0 1].freeze

    # Plural forms are compared as a group, because a locale has different forms than the base locale, and its forms
    # cover different counts: the Russian `one` is used for 1, 21, 31, ..., so it needs `%{count}` even when the
    # English `one` spells the number out. A form may only use the variables of the base forms, and must keep the
    # variables of the same base form (or of `other` if the base locale does not have it). It may drop `%{count}`
    # if it is used for at most one count, and must have it if it is used for several. The counts each form is used
    # for come from the locale's rule in rails-i18n.
    #
    # Keys that are not plural forms in the translated group have no base form to compare with, and are skipped.
    #
    # @return [Array<I18n::Tasks::Data::Tree::Node>] the inconsistent forms of `node`
    def inconsistent_plural_forms(locale, base_node, node)
      return [] unless node&.children?

      base_forms = base_node.children.to_h { |form| [form.key, interpolation_variables(form.value)] }
      base_vars = base_forms.values.reduce(Set.new, :|)
      forms = node.children.select { |form| form.leaf? && plural_suffix?(form.key) && form.value.is_a?(String) }
      form_counts = plural_form_counts(locale, node.children.map(&:key))
      forms.select do |form|
        vars = interpolation_variables(form.value)
        required = (base_forms[form.key] || base_forms["other"] || base_vars) - [COUNT_VARIABLE]
        if several_plural_counts?(form_counts, form.key) && base_vars.include?(COUNT_VARIABLE)
          required << COUNT_VARIABLE
        end
        !vars.subset?(base_vars) || !required.subset?(vars)
      end
    end

    def several_plural_counts?(form_counts, form_key)
      return !SINGLE_COUNT_PLURAL_FORMS.include?(form_key) if form_counts.nil?

      form_counts.fetch(form_key, 0) > 1
    end

    def interpolation_variables(value)
      value.is_a?(String) ? Set.new(value.scan(I18n::Tasks::Interpolations.variable_regex)) : Set.new
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
