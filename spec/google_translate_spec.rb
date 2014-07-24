# coding: utf-8
require 'spec_helper'
require 'i18n/tasks/commands'

describe 'Google Translation' do
  include I18n::Tasks::GoogleTranslation

  tests = [
      text_test = ['key', "Hello - %{user} O'neill!", "Hola - %{user} O'neill!"],
      html_test = ['html-key.html', "Hello - <b>%{user} O'neill</b>", "Hola - <b>%{user} O'neill</b>"],
      array_test = ['array-key', ['Hello.', 'Goodbye.'], ['Hola.', 'Adiós.']]
  ]


  if ENV['GOOGLE_TRANSLATE_API_KEY']
    describe 'real world test' do
      delegate :i18n_cmd, :i18n_task, :in_test_app_dir, to: :TestCodebase

      context '#google_translate_list' do
        it "works with #{tests.map(&:first)}" do
          # Just one test with all the cases to lower the Google bill
          translations = google_translate_list(
              tests.map { |t| t[0..1] }, from: :en, to: :es, key: ENV['GOOGLE_TRANSLATE_API_KEY'])
          expect(translations).to eq(tests.map { |t| [t[0], t[2]] })
        end
      end

      before do
        TestCodebase.setup('config/locales/en.yml' => '', 'config/locales/es.yml' => '')
      end

      after do
        TestCodebase.teardown
      end

      context 'command' do
        let(:task) { i18n_task }
        let(:cmd) { i18n_cmd(task) }

        it 'works' do
          in_test_app_dir do
            task.data[:en] = build_tree('en' => {
                'common' => {
                    'a' => 'λ',
                    'hello' => text_test[1],
                    'hello_html' => html_test[1],
                    'array_key' => array_test[1]
                }
            })
            task.data[:es] = build_tree('es' =>{
                'common' => {
                    'a' => 'λ',
                }
            })

            cmd.translate_missing
            expect(task.t('common.hello', 'es')).to eq(text_test[2])
            expect(task.t('common.hello_html', 'es')).to eq(html_test[2])
            expect(task.t('common.array_key', 'es')).to eq(array_test[2])
            expect(task.t('common.a', 'es')).to eq('λ')
          end
        end
      end
    end
  end
end
