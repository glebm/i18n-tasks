# coding: utf-8
module I18n::Tasks::Reports
  class Base

    def initialize
      @task = I18n::Tasks::BaseTask.new
    end

    attr_reader :task

    MISSING_TYPES = {
        none:    {glyph: '✗', summary: 'key missing'},
        blank:   {glyph: '∅', summary: 'translation blank'},
        eq_base: {glyph: '=', summary: 'value same as base value'}
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
  end
end