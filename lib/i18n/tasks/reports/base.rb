# coding: utf-8
module I18n::Tasks::Reports
  class Base

    def initialize
      @task = I18n::Tasks::BaseTask.new
    end

    attr_reader :task

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
  end
end
