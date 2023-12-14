# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Isolating router' do
  around do |spec|
    TestCodebase.setup(
      'app/components/movies_component.en.yml' => { en: { title: 'Movies' } }.to_yaml,
      'app/components/games_component.en.yml' => { en: { title: 'Games' } }.to_yaml
    )
    TestCodebase.in_test_app_dir { spec.run }
    TestCodebase.teardown
  end

  let(:translated_forest) do
    I18n::Tasks::Data::Tree::Siblings.from_nested_hash(
      fr: {
        '<app/components/movies_component.en.yml>': {
          title: 'Flims'
        },
        '<app/components/games_component.en.yml>': {
          title: 'Jeux'
        }
      }
    )
  end
  let(:data) do
    I18n::Tasks::Data::FileSystem.new(
      router: 'isolating_router',
      base_locale: 'en',
      read: ['app/components/*.%{locale}.yml']
    )
  end

  it 'namespaces each key within its file path' do
    expect(
      data['en']['en.<app/components/movies_component.en.yml>.title'].value
    ).to eq 'Movies'

    expect(
      data['en']['en.<app/components/games_component.en.yml>.title'].value
    ).to eq 'Games'
  end

  it 'routes each key to its original file alternate path' do
    file_assignments = data.router.route(:fr, translated_forest).to_h

    expect(
      file_assignments['app/components/movies_component.fr.yml']['fr.title'].value
    ).to eq 'Flims'

    expect(
      file_assignments['app/components/games_component.fr.yml']['fr.title'].value
    ).to eq 'Jeux'
  end

  describe 'alternate_path_for(source_path, locale)' do
    let(:read_config_patterns) { ['config/locales/**/*.%{locale}.yml'] }
    let(:router) { I18n::Tasks::Data::Router::IsolatingRouter.new(nil, { read: read_config_patterns }) }

    context 'when `source_path` matches a pattern of the `read` configuration' do
      it 'changes only the `%{locale}` part of `source_path`' do
        expect(
          router.alternate_path_for('config/locales/somewhere/hello.en.yml', :fr)
        ).to eq 'config/locales/somewhere/hello.fr.yml'
      end

      context 'when the `read` config has multiple `%{locale}` segments' do
        let(:read_config_patterns) { ['config/locales/%{locale}/**/*.%{locale}.yml'] }

        it 'changes all `%{locale}` parts' do
          expect(
            router.alternate_path_for('config/locales/en/hello.en.yml', :fr)
          ).to eq 'config/locales/fr/hello.fr.yml'
        end
      end
    end

    context 'when `source_path` matches none of the read patterns' do
      it 'returns `nil`' do
        expect(
          router.alternate_path_for('not_in_pattern/hello.en.yml', :fr)
        ).to be_nil
      end
    end
  end
end
