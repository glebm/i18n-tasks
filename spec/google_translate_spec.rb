# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/commands'

RSpec.describe 'Google Translation' do
  nil_value_test = ['nil-value-key', nil, nil]
  empty_value_test = ['empty-value-key', '', '']
  text_test      = ['key', "Hello, %{user} O'Neill!", "¡Hola, %{user} O'Neill!"]
  html_test      = ['html-key.html', "Hello, <b>%{user} O'neill</b>", "Hola, <b>%{user} O'neill</b>"]
  html_test_plrl = ['html-key.html.one', '<b>Hello %{count}</b>', '<b>Hola %{count}</b>']
  array_test     = ['array-key', ['Hello.', nil, '', 'Goodbye.'], ['Hola.', nil, '', 'Adiós.']]
  fixnum_test    = ['numeric-key', 1, 1]
  ref_key_test   = ['ref-key', :reference, :reference]

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

      it 'works' do
        skip 'temporarily disabled on JRuby due to https://github.com/jruby/jruby/issues/4802' if RUBY_ENGINE == 'jruby'
        skip 'GOOGLE_TRANSLATE_API_KEY env var not set' unless ENV['GOOGLE_TRANSLATE_API_KEY']
        skip 'GOOGLE_TRANSLATE_API_KEY env var is empty' if ENV['GOOGLE_TRANSLATE_API_KEY'].empty?
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
                                          'nil-value-key' => nil_value_test[1],
                                          'empty-value-key' => empty_value_test[1],
                                          'fixnum-key' => fixnum_test[1],
                                          'ref-key' => ref_key_test[1]
                                        }
                                      })
          task.data[:es] = build_tree('es' => {
                                        'common' => {
                                          'a' => 'λ'
                                        }
                                      })

          run_cmd 'translate-missing'
          expect(task.t('common.hello', 'es')).to eq(text_test[2])
          expect(task.t('common.hello_html', 'es')).to eq(html_test[2])
          expect(task.t('common.hello_plural_html.one', 'es')).to eq(html_test_plrl[2])
          expect(task.t('common.array_key', 'es')).to eq(array_test[2])
          expect(task.t('common.nil-value-key', 'es')).to eq(nil_value_test[2])
          expect(task.t('common.empty-value-key', 'es')).to eq(empty_value_test[2])
          expect(task.t('common.fixnum-key', 'es')).to eq(fixnum_test[2])
          expect(task.t('common.ref-key', 'es')).to eq(ref_key_test[2])
          expect(task.t('common.a', 'es')).to eq('λ')
        end
      end
    end
  end

  describe 'chinese simplified vs traditional' do
    delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase

    before do
      TestCodebase.setup(
        'config/locales/en.yml' => '',
        'config/locales/zh.yml' => '',
        'config/locales/zh-cn.yml' => '',
        'config/locales/zh-hans.yml' => '',
        'config/locales/zh-tw.yml' => '',
        'config/locales/zh-hant.yml' => '',
        'config/locales/zh-hk.yml' => '',
        'config/locales/es.yml' => '',
      )
    end

    after do
      TestCodebase.teardown
    end

    context 'command' do
      let(:task) { i18n_task }

      it 'should allow google to decide proper language from locale' do
        skip 'temporarily disabled on JRuby due to https://github.com/jruby/jruby/issues/4802' if RUBY_ENGINE == 'jruby'
        skip 'GOOGLE_TRANSLATE_API_KEY env var not set' unless ENV['GOOGLE_TRANSLATE_API_KEY']
        skip 'GOOGLE_TRANSLATE_API_KEY env var is empty' if ENV['GOOGLE_TRANSLATE_API_KEY'].empty?
        in_test_app_dir do
          task.data[:en] = build_tree('en' => { 'common' => { 'a' => 'λ', 'horse' => 'horse' } })

          # Loading translations seems to require at least one existing value.
          %w(zh zh-cn zh-hans zh-tw zh-hant zh-hk).each do |locale|
            task.data[locale] = build_tree(locale => { 'common' => { 'a' => 'λ' } })
          end

          run_cmd 'translate-missing'

          expect(task.t('common.horse', 'zh'     )).to eq("马") # Simplified Chinese
          expect(task.t('common.horse', 'zh-cn'  )).to eq("马") # Simplified Chinese
          expect(task.t('common.horse', 'zh-hans')).to eq("马") # Simplified Chinese
          expect(task.t('common.horse', 'zh-tw'  )).to eq("馬") # Traditional Chinese
          expect(task.t('common.horse', 'zh-hant')).to eq("馬") # Traditional Chinese
          expect(task.t('common.horse', 'zh-hk'  )).to eq("馬") # Traditional Chinese
        end
      end
    end
  end
end
