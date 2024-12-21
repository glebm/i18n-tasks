# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MissingKeys' do
  describe '#required_plural_keys_for_locale(locale)' do
    let(:task) { I18n::Tasks::BaseTask.new }

    def configuration_from(locale)
      {
        "#{locale}": {
          i18n: {
            plural: {
              keys: %i[one other],
              rule: -> {}
            }
          }
        }
      }
    end

    context 'when country code is lowercase' do
      let(:locale) { 'en-gb' }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale).and_return(configuration)
      end

      it 'accesses the capitalized country code key and returns a populated set' do
        expect(task.required_plural_keys_for_locale(locale)).not_to be_empty
      end
    end

    context 'when country code is uppercase' do
      let(:locale) { 'en-GB' }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale.downcase).and_return(configuration)
      end

      it 'accesses the capitalized country code key and returns a populated set' do
        expect(task.required_plural_keys_for_locale(locale.downcase)).not_to be_empty
      end
    end

    context 'when country code consists of three letters' do
      let(:locale) { 'zh-YUE' }
      let(:configuration) { configuration_from(locale) }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale.downcase).and_return(configuration)
      end

      it 'accesses the country code key and returns a populated set' do
        expect(task.required_plural_keys_for_locale(locale.downcase)).not_to be_empty
      end
    end

    context 'when locale is not present in configuration hash' do
      let(:locale) { 'zz-zz' }
      let(:configuration) { configuration_from('en-us') }

      before do
        allow(task).to receive(:load_rails_i18n_pluralization!).with(locale).and_return(configuration)
      end

      it 'returns an empty set' do
        expect(task.required_plural_keys_for_locale(locale)).to be_empty
      end
    end
  end

  describe '#missing_diff_forest(locale)' do
    let(:task) { I18n::Tasks::BaseTask.new }
    let(:base_keys) do
      {
        regular_key: 'a',
        other_key: 'b',

        plural_key: {
          one: 'one hat',
          other: '%{count} hats',
          zero: '%{count}'
        },

        ignored_pattern: {
          plural_key: {
            other: '%{count}'
          }
        }
      }
    end

    around do |ex|
      TestCodebase.setup(
        'config/i18n-tasks.yml' => {
          base_locale: 'en',
          locales: %w[en ru],
          ignore_missing: ['ignored_pattern.*']
        }.to_yaml,
        'config/locales/en.yml' => { en: base_keys }.to_yaml,
        'config/locales/ru.yml' => { ru: { regular_key: 'я' } }.to_yaml
      )
      TestCodebase.in_test_app_dir { ex.call }
      TestCodebase.teardown
    end

    it 'returns a hash of missing keys' do
      expected = {
        'ru' => {
          'other_key' => 'b',
          'plural_key' => {
            'one' => 'one hat',
            'other' => '%{count} hats',
            'zero' => '%{count}'
          }
        }
      }
      expect(task.missing_diff_forest(['ru']).to_hash).to eq(expected)
    end

    it 'skips values that are just interpolations' do
      expected = {
        'ru' => {
          'other_key' => 'b',
          'plural_key' => {
            'one' => 'one hat',
            'other' => '%{count} hats'
          }
        }
      }
      expect(task.missing_diff_forest(['ru'], 'en', true).to_hash).to eq(expected)
    end
  end
end
