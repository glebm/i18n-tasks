# coding: utf-8
module I18n::Tasks::Reports
  class Base
    include I18n::Tasks::Logging

    def initialize(task = I18n::Tasks::BaseTask.new)
      @task = task
    end

    attr_reader :task
    delegate :base_locale, :locales, to: :task

    MISSING_TYPES = {
        missing_from_base:   {glyph: '✗', summary: 'missing from base locale'},
        missing_from_locale: {glyph: '∅', summary: 'missing from locale but present in base locale'},
        eq_base: {glyph: '=', summary: 'value equals base value'}
    }

    def missing_types
      MISSING_TYPES
    end

    def missing_title(recs)
      "Missing translations (#{recs.length})"
    end

    def unused_title(recs)
      "Unused keys (#{recs.length})"
    end

    def used_title(used_tree)
      leaves = used_tree.leaves.to_a
      filter = used_tree.parent.data[:key_filter]
      used_n = leaves.map { |node| node.data[:source_locations].size }.reduce(:+).to_i
      "#{leaves.length} key#{'s' if leaves.size != 1}#{" ~ filter: '#{filter}'" if filter}#{" (#{used_n} usage#{'s' if used_n != 1})" if used_n > 0}"
    end
  end
end
