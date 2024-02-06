# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Interpolations' do
  let!(:task) { I18n::Tasks::BaseTask.new }

  let(:base_keys) do
    { 'a' => 'hello %{world}', 'b' => 'foo', 'c' => { 'd' => 'hello %{name}' }, 'e' => 'ok', 'f' => '%%{escaped}',
      'g' => 'okay' }
  end
  let(:test_keys) do
    { 'a' => 'hello', 'b' => 'foo %{bar}', 'c' => { 'd' => 'hola %{amigo}' }, 'e' => 'ok', 'f' => 'okay',
      'g' => '%%{ignored}' }
  end

  around do |ex|
    TestCodebase.setup(
      'config/i18n-tasks.yml' => { base_locale: 'en', locales: %w[es] }.to_yaml,
      'config/locales/en.yml' => { 'en' => base_keys }.to_yaml,
      'config/locales/es.yml' => { 'es' => test_keys }.to_yaml
    )

    TestCodebase.in_test_app_dir { ex.call }
    TestCodebase.teardown
  end

  context 'when using ruby string interpolations' do
    let(:base_keys) { { 'a' => 'hello %{world}', 'b' => 'foo', 'c' => { 'd' => 'hello %{name}' }, 'e' => 'ok' } }
    let(:test_keys) { { 'a' => 'hello', 'b' => 'foo %{bar}', 'c' => { 'd' => 'hola %{amigo}' }, 'e' => 'ok' } }

    it 'detects inconsistent interpolations' do
      wrong  = task.inconsistent_interpolations
      leaves = wrong.leaves.to_a

      expect(leaves.size).to eq 3
      expect(leaves[0].full_key).to eq 'es.a'
      expect(leaves[1].full_key).to eq 'es.b'
      expect(leaves[2].full_key).to eq 'es.c.d'
    end
  end

  context 'when using liquid tags' do
    let(:base_keys) do
      {
        a: 'hello {{ world }}',
        b: 'foo',
        c: {
          d: 'hello {{ name }}'
        },
        e: 'ok',
        f: 'inconsistent {{ whitespace}}',
        g: 'includes a {% comment %}',
        h: 'wrong {% comment %}',
        i: 'with localized value: {{ "thanks" | owner_invoice }}',
        j: 'with wrong function: {{ "thanks" | owner_invoices }}'
      }
    end
    let(:test_keys) do
      {
        a: 'hello',
        b: 'foo {{ bar }}',
        c: {
          d: 'hola {{ amigo }}'
        },
        e: 'ok',
        f: '{{whitespace }} inconsistentes',
        g: 'incluye un {% comment %}',
        h: '{% commentario %} equivocado',
        i: 'con valor localizado: {{ "gracias" | owner_invoice }}',
        j: 'con función incorrecta: {{ "thanks" | owner_invoice }}'
      }
    end

    it 'detects inconsistent interpolations' do
      wrong  = task.inconsistent_interpolations
      leaves = wrong.leaves.to_a

      expect(leaves.size).to eq 5
      expect(leaves[0].full_key).to eq 'es.a'
      expect(leaves[1].full_key).to eq 'es.b'
      expect(leaves[2].full_key).to eq 'es.c.d'
      expect(leaves[3].full_key).to eq 'es.h'
      expect(leaves[4].full_key).to eq 'es.j'
    end
  end
end
