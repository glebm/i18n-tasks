RSpec::Matchers.define :be_i18n_keys do |expected|
  match do |actual|
    actual.split("\n").map { |x| x.split(':')[0] }.sort == expected.sort
  end
end
