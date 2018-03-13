# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'

RSpec.describe 'CachingFileFinderProvider' do
  describe '#get' do
    it 'provides the same instance for the same arguments' do
      provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
      expect(provider.get(only: ['./a'])).to(
        be(provider.get(only: ['./a']))
      )
    end

    it 'provides different instances for different arguments' do
      provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
      expect(provider.get(only: ['./a'])).to_not(
        be(provider.get(only: ['./b']))
      )
    end
  end
end
