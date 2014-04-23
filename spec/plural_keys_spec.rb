require 'spec_helper'

describe 'Plural keys' do
  let(:task) { ::I18n::Tasks::BaseTask.new }
  before do
    TestCodebase.setup('config/locales/en.yml' => '')
    TestCodebase.in_test_app_dir do
      tree = ::I18n::Tasks::Data::Tree::Siblings.from_nested_hash('en' => {
          'regular_key'       => 'a',
          'plural_key'        => {
              'one' => 'one', 'other' => '%{count}'
          },
          'not_really_plural' => {
              'one'   => 'a',
              'green' => 'b'
          }
      })
      task.data['en'] = tree
      task.data['en']
    end
  end

  describe '#depluralize_key' do
    it 'depluralizes plural keys' do
      expect(depluralize('plural_key.one')).to eq('plural_key')
    end

    it 'ignores regular keys' do
      expect(depluralize('regular_key')).to eq('regular_key')
    end

    it 'ignores keys that look like plural but are not' do
      expect(depluralize('not_really_plural.one')).to eq('not_really_plural.one')
    end

    def depluralize(key)
      task.depluralize_key(key, 'en')
    end
  end

  after do
    TestCodebase.teardown
  end
end
