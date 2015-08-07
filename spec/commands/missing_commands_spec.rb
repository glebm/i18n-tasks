require 'spec_helper'

RSpec.describe 'Data commands' do
  delegate :run_cmd, to: :TestCodebase

  describe '#add_missing' do
    describe 'adds the missing keys to base locale first, then to other locales' do
      around do |ex|
        TestCodebase.setup(
            'config/i18n-tasks.yml' => {base_locale: 'en', locales: %w(es fr)}.to_yaml,
            'config/locales/es.yml' => {'es' => {'a' => 'A'}}.to_yaml)
        TestCodebase.in_test_app_dir { ex.call }
        TestCodebase.teardown
      end

      it 'with -v argument' do
        run_cmd 'add-missing', '-vTRME'
        expect(YAML.load_file('config/locales/en.yml')).to eq('en' => {'a' => 'TRME'})
        expect(YAML.load_file('config/locales/fr.yml')).to eq('fr' => {'a' => 'TRME'})
      end
    end
  end
end
