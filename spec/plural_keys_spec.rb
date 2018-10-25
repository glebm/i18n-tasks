# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Plural keys' do
  let(:task) { ::I18n::Tasks::BaseTask.new }

  let(:base_keys) do
    {
      regular_key: 'a',

      plural_key: {
        one: 'one',
        other: '%{count}'
      },

      not_really_plural: {
        one: 'a',
        green: 'b'
      },

      nested: {
        plural_key: {
          zero: 'none',
          one: 'one',
          other: '%{count}'
        }
      }
    }
  end

  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => { base_locale: 'en', locales: %w[en ar] }.to_yaml,
      'config/locales/en.yml' => { en: base_keys }.to_yaml,
      'config/locales/ar.yml' => { ar: base_keys }.to_yaml
    )
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
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

  describe '#missing_plural_forest' do
    it 'returns keys with missing pluralizations' do
      wrong  = task.missing_plural_forest(%w[en ar])
      leaves = wrong.leaves.to_a

      expect(leaves.size).to eq 2
      expect(leaves[0].full_key).to eq 'ar.plural_key'
      expect(leaves[0].data[:missing_keys]).to eq %i[zero two few many]
      expect(leaves[1].full_key).to eq 'ar.nested.plural_key'
      expect(leaves[1].data[:missing_keys]).to eq %i[two few many]
    end
  end
end
