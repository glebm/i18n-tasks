# coding: utf-8
RSpec::Matchers.define :be_i18n_keys do |expected|
  def locale_re
    /^\w{2}\b/
  end
  
  def extract_keys(actual)
    locales = I18n.available_locales.map(&:to_s)
    actual.split("\n").map { |x|
      key = x.gsub(/\s+/, ' ').split(' ').reverse.detect { |p| p && p.include?('.') }
      if x =~ locale_re && locales.include?(x[0..1]) && !(key =~ locale_re && locales.include?(key[0..1]))
        key = x.split(' ', 2)[0] + '.' + key
      end
      key = key[0..-2] if key.end_with?(':')
      key
    }.compact
  end

  match do |actual|
    extract_keys(actual).should =~ expected
  end

  failure_message_for_should do |actual|
    e = expected.sort
    a = extract_keys(actual).sort

    <<-MSG.strip
Expected #{e}, but had #{a}. Diff:

missing: #{e-a}
extra:   #{a-e}
    MSG
  end
end
