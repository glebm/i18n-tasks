module I18n::Tasks
  module StringInterpolation
    extend self

    def interpolate_soft(s, t = {})
      return s unless s
      t.each do |k, v|
        pat = "%{#{k}}"
        s = s.gsub pat, v.to_s if s.include?(pat)
      end
      s
    end
  end
end
