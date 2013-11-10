require 'spec_helper'
describe 'README.md' do
  let(:readme) { File.read('README.md') }
  it 'has valid YAML in ```yaml blocks' do
    readme.scan /```yaml\n(.*)(?=^)\n```/ do |m|
      expect { YAML.load(m[0]) }.to_not raise_errors
    end
  end
end
