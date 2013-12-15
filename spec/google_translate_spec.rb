require 'spec_helper'

describe 'Google Translation' do
  include I18n::Tasks::GoogleTranslation

  if ENV['GOOGLE_TRANSLATE_API_KEY']
    context 'real world test' do
      it 'works' do
        google_translate(
            [['common.hello', "Hello, %{user}!"]], from: :en, to: :es, key: ENV['GOOGLE_TRANSLATE_API_KEY']
        ).should == [['common.hello', 'Hola, %{user}!']]
      end
    end
  end
end
