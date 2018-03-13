# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'LocalePathname' do
  context '#replace_locale' do
    def replace_locale(path, from, to)
      ::I18n::Tasks::LocalePathname.replace_locale(path, from, to)
    end

    it 'es.yml' do
      expect(replace_locale('es.yml', 'es', 'fr')).to eq 'fr.yml'
    end

    it 'scope.es.yml' do
      expect(replace_locale('scope.es.yml', 'es', 'fr')).to eq 'scope.fr.yml'
    end

    it 'path/es.yml' do
      expect(replace_locale('path/es.yml', 'es', 'fr')).to eq 'path/fr.yml'
    end

    it 'path/scope.es.yml' do
      expect(replace_locale('path/scope.es.yml', 'es', 'fr')).to eq 'path/scope.fr.yml'
    end
  end
end
