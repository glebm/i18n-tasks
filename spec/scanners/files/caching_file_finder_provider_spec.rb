require 'spec_helper'
require 'i18n/tasks/scanners/files/caching_file_finder_provider'

RSpec.describe 'CachingFileFinderProvider' do
  describe '#get' do
    it 'provides the same instance for the same arguments' do
      provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
      expect(provider.get(include: ['./a'])).to(
          be(provider.get(include: ['./a'])))
    end

    it 'provides different instances for different arguments' do
      provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
      expect(provider.get(include: ['./a'])).to_not(
          be(provider.get(include: ['./b'])))
    end
  end
end
