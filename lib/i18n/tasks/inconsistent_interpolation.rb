# frozen_string_literal: true

module I18n::Tasks
  module InconsistentInterpolation
    VARIABLE_REGEX = /%{[^}]+}/

    def inconsistent_interpolation(locales: nil, base_locale: nil)
      locales ||= self.locales
      base      = base_locale || self.base_locale
      tree      = empty_forest

      data[base].key_values.each do |key, value|
        next if ignore_key?(key, :inconsistent) || !value.is_a?(String)

        base_variables = Set.new(value.scan(VARIABLE_REGEX))

        (locales - [base]).each do |current_locale|
          node = data[current_locale].first.children[key]

          next if !node&.value&.is_a?(String) || base_variables == Set.new(node.value.scan(VARIABLE_REGEX))

          tree.merge! inconsistent_interpolation_tree(current_locale, key)
        end
      end

      tree
    end

    def inconsistent_interpolation_tree(locale, key)
      data[locale].select_keys(root: false) { |x| x == key }
                  .set_root_key!(locale, type: :inconsistent_interpolation)
    end
  end
end
