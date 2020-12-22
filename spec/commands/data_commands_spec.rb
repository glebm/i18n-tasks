# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Data commands' do
  delegate :run_cmd, :in_test_app_dir, to: :TestCodebase
  def en_data
    { 'en' => { 'a' => '1', 'common' => { 'hello' => 'Hello' } } }
  end

  def en_data2
    { 'en' => { 'common' => { 'hi' => 'Hi' } } }
  end

  before do
    TestCodebase.setup('config/locales/en.yml' => en_data.to_yaml)
  end

  after do
    TestCodebase.teardown
  end

  it '#data' do
    expect(JSON.parse(run_cmd('data', '-fjson', '-len'))).to eq(en_data)
  end

  it '#data-merge' do
    expect(JSON.parse(run_cmd('data-merge', '-fjson', '-S', en_data2.to_json))).to eq(en_data.deep_merge(en_data2))
  end

  it '#data-write' do
    expect(JSON.parse(run_cmd('data-write', '-fjson', '-S', en_data2.to_json))).to eq(en_data2)
  end

  it '#data-remove' do
    to_remove = { 'en' => { 'common' => { 'hello' => '' } } }
    expect(JSON.parse(run_cmd('data-remove', '-fjson', '-S', to_remove.to_json))).to(
      eq('en' => { 'common' => en_data['en']['common'] })
    )
  end

  it '#mv' do
    run_cmd('mv', 'a', 'b')
    expect(in_test_app_dir { YAML.load_file('config/locales/en.yml') })
      .to(eq('en' => { 'b' => '1', 'common' => { 'hello' => 'Hello' } }))
  end
end
