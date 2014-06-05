# coding: utf-8
RSpec::Matchers.define :match_key do |key|
  include I18n::Tasks::KeyPatternMatching

  match do |pattern|
    expect(compile_key_pattern(pattern)).to match(key)
  end
end
