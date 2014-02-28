require 'spec_helper'
require 'i18n/tasks/commands'

describe 'Google Translation' do
  include I18n::Tasks::GoogleTranslation

  TEST_STRING = 'Hello, %{user}!'
  TEST_RESULT = 'Hola, %{user}!'

  if ENV['GOOGLE_TRANSLATE_API_KEY']
    describe 'real world test' do
      delegate :i18n_cmd, :i18n_task, :in_test_app_dir, to: :TestCodebase

      context 'API' do
        it 'works' do
          google_translate(
              [['common.hello', TEST_STRING]], from: :en, to: :es, key: ENV['GOOGLE_TRANSLATE_API_KEY']
          ).should == [['common.hello', TEST_RESULT]]
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
            task.data[:en] = {'common' => {'hello' => TEST_STRING}}
            cmd.translate_missing
            expect(task.data[:es].t('common.hello')).to eq(TEST_RESULT)
          end
        end
      end
    end
  end
end
