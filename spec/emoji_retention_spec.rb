# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Emoji Retention in dump' do
  let(:yaml) { { 'a' => 'hello %{world}😀', 'b' => 'foo', 'c' => { 'd' => 'hello %{name}' }, 'e' => 'ok' } }

  describe '.dump' do
    it 'does not strip emojis from yaml' do
      dumped_yaml = I18n::Tasks::Data::Adapter::YamlAdapter.dump(
        yaml,
        {}
      )
      expect(dumped_yaml).to include('😀')
    end
  end
end
