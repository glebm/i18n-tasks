require 'spec_helper'

describe 'Data commands' do
  delegate :run_cmd, to: :TestCodebase
  def en_data
    {'en' => {'a' => '1', 'common' => {'hello' => 'Hello'}}}
  end

  def en_data_2
    {'en' => {'common' => {'hi' => 'Hi'}}}
  end


  before do
    TestCodebase.setup('config/locales/en.yml' => en_data.to_yaml)
  end

  after do
    TestCodebase.teardown
  end

  it '#data' do
    expect(JSON.parse(run_cmd 'data', '-fjson', '-len')).to eq(en_data)
  end

  it '#data-merge' do
    expect(JSON.parse(run_cmd 'data-merge', '-fjson', '-S', en_data_2.to_json)).to eq(en_data.deep_merge en_data_2)
  end

  it '#data-write' do
    expect(JSON.parse(run_cmd 'data-write', '-fjson', '-S', en_data_2.to_json)).to eq(en_data_2)
  end

  it '#data-remove' do
    to_remove = {'en' => {'common' => {'hello' => ''}}}
    expect(JSON.parse(run_cmd 'data-remove', '-fjson', '-S', to_remove.to_json)).to eq('en' => {'common' => en_data['en']['common'] })
  end
end
