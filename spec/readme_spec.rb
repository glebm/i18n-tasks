require 'spec_helper'
describe 'README.md' do
  let(:readme) { File.read('README.md') }
  it '```yaml blocks' do
    readme.scan /```yaml\n(.*)(?=^)\n```/ do |m|
      YAML.load(m[0]).should be_a(Hash)
    end
  end
end