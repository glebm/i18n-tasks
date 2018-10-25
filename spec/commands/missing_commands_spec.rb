# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Missing commands' do
  delegate :run_cmd, to: :TestCodebase

  let(:missing_keys) { { 'a' => 'A', 'ref' => :ref } }
  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => { base_locale: 'en', locales: %w[es fr] }.to_yaml,
      'config/locales/es.yml' => { 'es' => missing_keys }.to_yaml
    )
    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe '#add_missing' do
    describe 'adds the missing keys to base locale first, then to other locales' do
      it 'with -v argument' do
        run_cmd 'add-missing', '-vTRME'
        created_keys = missing_keys.dup
        created_keys['a'] = 'TRME'
        expect(YAML.load_file('config/locales/en.yml')).to eq('en' => created_keys)
        expect(YAML.load_file('config/locales/fr.yml')).to eq('fr' => created_keys)
      end
    end
  end

  describe '#missing' do
    describe 'returns missing keys' do
      it 'with -t diff argument' do
        expect(YAML.load(run_cmd('missing', '-tdiff', '-fyaml'))).to eq('en' => missing_keys)
      end

      it 'with -t used argument' do
        expect(YAML.load(run_cmd('missing', '-tused', '-fyaml'))).to eq({})
      end

      it 'with -t plural argument' do
        expect(YAML.load(run_cmd('missing', '-tplural', '-fyaml'))).to eq({})
      end

      it 'with invalid -t argument' do
        expect { run_cmd 'missing', '-tinvalid' }.to raise_error(I18n::Tasks::CommandError)
      end
    end
  end
end
