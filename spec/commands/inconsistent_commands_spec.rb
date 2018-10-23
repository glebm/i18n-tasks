# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Inconsistent commands' do
  delegate :run_cmd, :in_test_app_dir, to: :TestCodebase

  let(:base_keys) { { 'a' => 'hello %{world}', 'b' => 'foo', 'c' => { 'd' => 'hello %{name}' }, 'e' => 'ok' } }
  let(:test_keys) { { 'a' => 'hello', 'b' => 'foo %{bar}', 'c' => { 'd' => 'hola %{amigo}' }, 'e' => 'ok' } }

  let(:wrong_subtree) { { 'es' => test_keys.slice('a', 'b', 'c') } }

  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => { base_locale: 'en', locales: %w[es] }.to_yaml,
      'config/locales/en.yml' => { 'en' => base_keys }.to_yaml,
      'config/locales/es.yml' => { 'es' => test_keys }.to_yaml
    )

    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  describe '#check_consistent_interpolations' do
    it 'returns inconsistent keys' do
      expect(YAML.load(run_cmd('check-consistent-interpolations', '-fyaml'))).to eq(wrong_subtree)
    end
  end
end
