# frozen_string_literal: true

require 'i18n/tasks/scanners/ast_matchers/base_matcher'
require 'i18n/tasks/scanners/results/occurrence'

module I18n::Tasks::Scanners::AstMatchers
  class DefaultI18nSubjectMatcher < BaseMatcher
    def convert_to_key_occurrences(send_node, method_name, location: send_node.loc)
      children = Array(send_node&.children)
      return unless children[1] == :default_i18n_subject

      key = @scanner.absolute_key(
        '.subject',
        location.expression.source_buffer.name,
        calling_method: method_name
      )
      [
        key,
        I18n::Tasks::Scanners::Results::Occurrence.from_range(
          raw_key: key,
          range: location.expression
        )
      ]
    end
  end
end
