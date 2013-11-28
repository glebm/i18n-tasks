# coding: utf-8
RSpec::Matchers.define :match_key do |key|
  include I18n::Tasks::KeyPatternMatching

  match do |pattern|
    compile_key_pattern(pattern).should =~ key
  end
end
