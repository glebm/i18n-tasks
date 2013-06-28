RSpec::Matchers.define :be_i18n_keys do |expected|
  match do |actual|
    r = actual.split("\n").map { |x|
      x.strip!
      key = x.gsub(/\s+/, ' ').split(' ').reverse.detect { |p| p && p.include?('.') }
      if x =~ /^\w{2}\b/
        x.split(' ', 2)[0] + '.' + key
      else
        key
      end
    }
    r.sort == expected.sort
  end
end
