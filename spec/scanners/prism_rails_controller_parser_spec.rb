# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/prism_rails_controller_parser'

RSpec.describe 'PrismRailsControllerParser' do
  describe '#process - controller' do
    it 'finds translations' do
      path = "spec/fixtures/used_keys/app/controllers/events_controller.rb"
      processor = I18n::Tasks::Scanners::PrismRailsControllerParser.new
      results = processor.process_path(path)

      expect(results.size).to eq(8)
    end
  end
end
