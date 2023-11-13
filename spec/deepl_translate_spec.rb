# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/commands'
require 'deepl'

RSpec.describe 'DeepL Translation' do
  nil_value_test  = ['nil-value-key', nil, nil]
  text_test       = ['key', "Hello, %{user} O'Neill! How are you?", "¡Hola, %{user} O'Neill! ¿Qué tal estás?"]
  html_test_plrl  = ['html-key.html.one', '<span>Hello %{count}</span>', '<span>Hola %{count}</span>']
  array_test      = ['array-key', ['Hello.', nil, '', 'Goodbye.'], ['Hola.', nil, '', 'Adiós.']]
  array_hash_test = ['array-hash-key',
                     [{ 'hash_key1' => 'How are you?' }, { 'hash_key2' => nil }, { 'hash_key3' => 'Well.' }],
                     [{ 'hash_key1' => '¿Qué tal?' }, { 'hash_key2' => nil }, { 'hash_key3' => 'Bien.' }]]
  fixnum_test     = ['numeric-key', 1, 1]
  ref_key_test    = ['ref-key', :reference, :reference]
  # this test fails atm due to moving of the bold tag =>  "Hola, <b>%{user} </b> gran O'neill ❤︎ "
  # it could be a bug, but the api also allows to ignore certain tags and there is the new html-markup version which
  # could be used too
  html_test       = ['html-key.html', "Hello, <b>%{user} big O'neill</b> ❤︎", "Hola, <b>%{user} gran O'neill</b> ❤︎"]
  support_test    = ['support', '%{model} or similar', '%{model} o similar']

  describe 'real world test' do
    delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase

    before do
      TestCodebase.setup('config/locales/en.yml' => '', 'config/locales/es.yml' => '')
    end

    after do
      TestCodebase.teardown
    end

    context 'command' do
      let(:task) { i18n_task }

      it 'works' do # rubocop:disable RSpec/MultipleExpectations
        skip 'temporarily disabled on JRuby due to https://github.com/jruby/jruby/issues/4802' if RUBY_ENGINE == 'jruby'
        skip 'DEEPL_AUTH_KEY env var not set' unless ENV['DEEPL_AUTH_KEY']
        in_test_app_dir do
          task.data[:en] = build_tree('en' => {
                                        'common' => {
                                          'a' => 'λ',
                                          'hello' => text_test[1],
                                          'hello_html' => html_test[1],
                                          'hello_plural_html' => {
                                            'one' => html_test_plrl[1]
                                          },
                                          'array_key' => array_test[1],
                                          'array_hash_key' => array_hash_test[1],
                                          'nil-value-key' => nil_value_test[1],
                                          'fixnum-key' => fixnum_test[1],
                                          'ref-key' => ref_key_test[1],
                                          'support' => support_test[1],
                                          'needs_escaping' => 'Cars << Trucks / %{keep_this}',
                                          'needs_escaping_html' => '<span>Cars</span> << Trucks / %{keep_this}'
                                        }
                                      })
          task.data[:es] = build_tree('es' => {
                                        'common' => {
                                          'a' => 'λ'
                                        }
                                      })

          run_cmd 'translate-missing', '--backend=deepl'
          expect(task.t('common.hello', 'es')).to eq(text_test[2])
          expect(task.t('common.hello_plural_html.one', 'es')).to eq(html_test_plrl[2])
          expect(task.t('common.array_key', 'es')).to eq(array_test[2])
          expect(task.t('common.nil-value-key', 'es')).to eq(nil_value_test[2])
          expect(task.t('common.fixnum-key', 'es')).to eq(fixnum_test[2])
          expect(task.t('common.ref-key', 'es')).to eq(ref_key_test[2])
          expect(task.t('common.a', 'es')).to eq('λ')
          expect(task.t('common.hello_html', 'es')).to eq(html_test[2])
          expect(task.t('common.support', 'es')).to eq(support_test[2])
          expect(task.t('common.needs_escaping', 'es')).to eq('Coches << Camiones / %{keep_this}')
          # The << is automatically escaped when calling the translation service
          expect(
            task.t('common.needs_escaping_html', 'es')
          ).to eq('<span>Coches</span> &lt;&lt; Camiones / %{keep_this}')
        end
      end
    end
  end
end
