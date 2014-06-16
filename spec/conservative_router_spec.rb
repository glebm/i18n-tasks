# coding: utf-8
require 'spec_helper'

describe 'Conservative router' do
  describe '#available_locales' do
    before do
      TestCodebase.setup(
          'config/locales/en.yml'       => {en: {a: 1}}.to_yaml,
          'config/locales/other.en.yml' => {en: {b: 1}}.to_yaml,
          'config/locales/es.yml'       => {es: {}}.to_yaml,
          'config/locales/other.es.yml' => {es: {c: 1}}.to_yaml
      )
    end
    after do
      TestCodebase.teardown
    end
    let(:data) {
      I18n::Tasks::Data::FileSystem.new(
          router:      'conservative_router',
          base_locale: 'en',
          read:        'config/locales/*%{locale}.yml',
          write:       ['config/locales/not_found.%{locale}.yml']
      )
    }

    it 'preserves existing keys' do
      TestCodebase.in_test_app_dir do
        data['es'] = data['es']
        data.reload
        expect(data['es']['es.c'].data[:path]).to eq('config/locales/other.es.yml')
      end
    end

    it 'infers new keys from base locale' do
      TestCodebase.in_test_app_dir do
        data['es'] = data['es'].merge!(build_tree(es: {a: 1, b: 2}))
        data.reload
        expect(data['es']['es.a'].data[:path]).to eq('config/locales/es.yml')
        expect(data['es']['es.b'].data[:path]).to eq('config/locales/other.es.yml')
      end
    end

    it 'falls back to pattern_router when the key is new' do
      TestCodebase.in_test_app_dir do
        data['es'] = data['es'].merge!(build_tree(es: {z: 2}))
        data.reload
        expect(data['es']['es.z'].data[:path]).to eq('config/locales/not_found.es.yml')
      end
    end
  end
end
