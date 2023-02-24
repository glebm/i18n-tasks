require 'spec_helper'

RSpec.describe I18n::Tasks::Data::Tree::Traversal do
  delegate :i18n_task, to: :TestCodebase

  describe '#grep_keys' do
    it 'returns Siblings' do
      expect(i18n_task.data['en'].grep_keys(/key/)).to be_a(I18n::Tasks::Data::Tree::Siblings)
    end
  end

  # --- setup ---
  before(:each) do
    TestCodebase.setup fixtures_contents
  end

  after do
    TestCodebase.teardown
  end
end
