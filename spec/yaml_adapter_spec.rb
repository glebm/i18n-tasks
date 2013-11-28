require 'spec_helper'

describe 'YAML adapter' do
  describe 'options' do
    let!(:data) { I18n::Tasks::Data::Yaml.new }
    after { TestCodebase.teardown }

    it 'reads' do
      data.config = {read: ['a.yml', '{b,c}.yml']}
      TestCodebase.setup(
          'a.yml' => {en: {a: 1}}.stringify_keys.to_yaml,
          'b.yml' => {en: {b: 1}}.stringify_keys.to_yaml,
          'c.yml' => {en: {c: 1}}.stringify_keys.to_yaml
      )
      TestCodebase.in_test_app_dir {
        data[:en].should == {a: 1, b: 1, c: 1}
      }
    end

    it 'writes' do
      data.config = {read: 'a.yml', write: [['{:}.*', '\1.%{locale}.yml']]}
      keys        = {'a' => {'b' => 'c'}, 'x' => 'y'}
      locale_data = {'pizza' => keys, 'sushi' => keys}
      TestCodebase.setup
      TestCodebase.in_test_app_dir {
        data[:en] = locale_data
        files     = %w(pizza.en.yml sushi.en.yml)
        Dir['*.yml'].should == files.sort
        files.each { |f| YAML.load_file(f)['en'].should == {File.basename(f, '.en.yml') => keys} }
      }
    end
  end
end