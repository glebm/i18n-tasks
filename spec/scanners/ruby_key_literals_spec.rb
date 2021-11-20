# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/ruby_key_literals'

RSpec.describe 'RubyKeyLiterals' do
  let(:scanner) do
    Object.new.extend I18n::Tasks::Scanners::RubyKeyLiterals
  end

  describe '#literal_re' do
    subject do
      /(#{scanner.literal_re})/x =~ key
      Regexp.last_match(1)
    end

    context 'string' do
      context 'single quoted' do
        let(:key) { %('some_key') }
        it { is_expected.to eq(key) }
      end

      context 'double quoted' do
        context 'var' do
          let(:key) { %q("#{some_key}") } # rubocop:disable Lint/InterpolationCheck
          it { is_expected.to eq(key) }
        end

        context 'hash' do
          context 'double quoted key' do
            let(:key) { %q("#{some_hash["some_key"]}") } # rubocop:disable Lint/InterpolationCheck
            it { is_expected.to eq(key) }
          end

          context 'single quoted key' do
            let(:key) { %q("#{some_hash['some_key']}") } # rubocop:disable Lint/InterpolationCheck
            it { is_expected.to eq(key) }
          end

          context 'symbol key' do
            let(:key) { %q("#{some_hash[:some_key]}") } # rubocop:disable Lint/InterpolationCheck
            it { is_expected.to eq(key) }
          end
        end
      end
    end

    context 'symbol' do
      context 'regular literal' do
        let(:key) { %(:some_key) }
        it { is_expected.to eq(key) }
      end

      context 'single quoted' do
        let(:key) { %(:'some_key') }
        it { is_expected.to eq(key) }
      end

      context 'double quoted' do
        let(:key) { %q(:"#{some_key}") } # rubocop:disable Lint/InterpolationCheck
        it { is_expected.to eq(key) }
      end
    end
  end

  describe '#valid_key?' do
    it 'allows forward slash in key' do
      expect(scanner).to be_valid_key('category/product')
    end
  end
end
