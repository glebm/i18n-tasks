# frozen_string_literal: true

module I18n::Tasks
  module StringInterpolation
    module_function

    def interpolate_soft(s, t = {})
      return s unless s

      # A lone placeholder keeps the value's type, so that an array stays an array
      lone_placeholder = s[/\A%\{(\w+)\}\z/, 1]&.to_sym
      return t[lone_placeholder] if t.key?(lone_placeholder) && !t[lone_placeholder].nil?

      t.each do |k, v|
        pat = "%{#{k}}"
        s = s.gsub pat, v.to_s if s.include?(pat)
      end
      s
    end
  end
end
