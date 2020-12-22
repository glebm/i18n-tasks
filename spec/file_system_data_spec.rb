# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'File system i18n' do
  describe '#available_locales' do
    before do
      TestCodebase.setup(
        'config/locales/en.yml' => { en: {} },
        'config/locales/es.yml' => { es: {} },
        'config/locales/other.fr.yml' => { fr: {} }
      )
    end
    after do
      TestCodebase.teardown
    end
    let(:data) { I18n::Tasks::Data::FileSystem.new }
    it 'default pattern' do
      data.config = { read: ['config/locales/%{locale}.yml'] }
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[en es].sort)
      end
    end
    it 'more inclusive pattern' do
      data.config = { read: ['config/locales/*%{locale}.yml'] }
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[en es fr].sort)
      end
    end
    it 'another pattern' do
      data.config = { read: ['config/locales/*.%{locale}.yml'] }
      TestCodebase.in_test_app_dir do
        expect(data.available_locales.sort).to eq(%w[fr].sort)
      end
    end
  end

  describe '#get' do
    let(:data) { I18n::Tasks::Data::FileSystem.new }
    after { TestCodebase.teardown }

    it 'includes problematic YAML file path in exception message' do
      data.config = { read: ['invalid.yml'] }
      TestCodebase.setup('invalid.yml' => '%')
      TestCodebase.in_test_app_dir do
        expect { data.get(:invalid) }
          .to raise_error(I18n::Tasks::CommandError) do |error|
            expect(error.message).to end_with('(file: invalid.yml)')
          end
      end
    end

    it 'includes problematic JSON file path in exception message' do
      data.config = { read: ['invalid.json'] }
      TestCodebase.setup('invalid.json' => '-')
      TestCodebase.in_test_app_dir do
        expect { data.get(:invalid) }
          .to raise_error(I18n::Tasks::CommandError) do |error|
            expect(error.message).to end_with('(file: invalid.json)')
          end
      end
    end
  end

  describe 'yml' do
    let(:data) { I18n::Tasks::Data::FileSystem.new }
    after { TestCodebase.teardown }

    it '#get' do
      data.config = { read: ['a.yml', '{b,c}.yml'] }
      TestCodebase.setup(
        'a.yml' => { en: { a: 1 } }.stringify_keys.to_yaml,
        'b.yml' => { en: { b: 1 } }.stringify_keys.to_yaml,
        'c.yml' => { en: { c: 1 } }.stringify_keys.to_yaml
      )
      TestCodebase.in_test_app_dir do
        actual = data[:en].to_hash['en'].symbolize_keys
        expect(actual).to eq(a: 1, b: 1, c: 1)
      end
    end

    it '#set' do
      data.config = { read: 'a.yml', write: [['{:}.*', '\1.%{locale}.yml']] }
      keys = { 'a' => { 'b' => 'c' }, 'x' => 'y' }
      locale_data = { 'pizza' => keys, 'sushi' => keys }
      TestCodebase.setup
      TestCodebase.in_test_app_dir do
        data[:en] = data[:en].merge!({ 'en' => locale_data })
        files = %w[pizza.en.yml sushi.en.yml]
        expect(Dir['*.yml'].sort).to eq(files.sort)
        files.each { |f| expect(YAML.load_file(f)['en']).to eq(File.basename(f, '.en.yml') => keys) }
      end
    end
  end

  describe 'json' do
    let!(:data) do
      I18n::Tasks::Data::FileSystem.new(
        read: ['config/locales/%{locale}.json'],
        write: ['config/locales/%{locale}.json']
      )
    end
    after { TestCodebase.teardown }

    it 'reads' do
      data.config = { read: ['a.json', '{b,c}.json'] }
      TestCodebase.setup(
        'a.json' => { en: { a: 1 } }.stringify_keys.to_json,
        'b.json' => { en: { b: 1 } }.stringify_keys.to_json,
        'c.json' => { en: { c: 1 } }.stringify_keys.to_json
      )
      TestCodebase.in_test_app_dir do
        expect(data[:en].to_hash['en'].symbolize_keys).to eq(a: 1, b: 1, c: 1)
      end
    end

    it 'writes' do
      data.config = { read: 'a.json', write: [['{:}.*', '\1.%{locale}.json']] }
      keys = { 'a' => { 'b' => 'c' }, 'x' => 'y' }
      locale_data = { 'pizza' => keys, 'sushi' => keys }
      TestCodebase.setup
      TestCodebase.in_test_app_dir do
        data[:en] = data[:en].merge!({ 'en' => locale_data })
        files = %w[pizza.en.json sushi.en.json]
        expect(Dir['*.json'].sort).to eq(files.sort)
        files.each do |f|
          expect(JSON.parse(File.read(f, encoding: 'UTF-8'))['en']).to eq(File.basename(f, '.en.json') => keys)
        end
      end
    end
  end
end
