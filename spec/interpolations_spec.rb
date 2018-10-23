# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Interpolations' do
  let!(:task) { I18n::Tasks::BaseTask.new }

  let(:base_keys) { { 'a' => 'hello %{world}', 'b' => 'foo', 'c' => { 'd' => 'hello %{name}' }, 'e' => 'ok' } }
  let(:test_keys) { { 'a' => 'hello', 'b' => 'foo %{bar}', 'c' => { 'd' => 'hola %{amigo}' }, 'e' => 'ok' } }

  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => { base_locale: 'en', locales: %w[es] }.to_yaml,
      'config/locales/en.yml' => { 'en' => base_keys }.to_yaml,
      'config/locales/es.yml' => { 'es' => test_keys }.to_yaml
    )

    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  it '#inconsistent_interpolation' do
    wrong  = task.inconsistent_interpolations
    leaves = wrong.leaves.to_a

    expect(leaves.size).to eq 3
    expect(leaves[0].full_key).to eq 'es.a'
    expect(leaves[1].full_key).to eq 'es.b'
    expect(leaves[2].full_key).to eq 'es.c.d'
  end
end
