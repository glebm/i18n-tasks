# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MissingKeys' do
  describe '#required_plural_keys_for_locale(locale)' do
    let(:task) { ::I18n::Tasks::BaseTask.new }

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
end
