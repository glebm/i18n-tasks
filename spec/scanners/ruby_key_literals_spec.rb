# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/ruby_key_literals'

RSpec.describe 'RubyKeyLiterals' do
  let(:scanner) do
    Object.new.extend I18n::Tasks::Scanners::RubyKeyLiterals
  end

  describe '#valid_key?' do
    it 'allows forward slash in key' do
      expect(scanner).to be_valid_key('category/product')
    end
  end
end
