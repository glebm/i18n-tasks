# coding: utf-8
require 'spec_helper'
describe 'README.md' do
  let(:readme) do
    encoding_options = {
      :invalid => :replace,
      :undef => :replace,
      :replace => '',
      :UNIVERSAL_NEWLINE_DECORATOR => true
    }
    File.read('README.md').encode(Encoding.find('ASCII'), encoding_options)
  end

  it 'has valid YAML in ```yaml blocks' do
    readme.scan /```yaml\n(.*)(?=^)\n```/ do |m|
      expect { YAML.load(m[0]) }.to_not raise_errors
    end
  end
end
