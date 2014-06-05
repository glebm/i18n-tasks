require 'spec_helper'
describe 'Relative keys' do
  let(:scanner) { I18n::Tasks::Scanners::BaseScanner.new }

  describe 'absolutize_key' do

    context 'default settings' do
      it 'works' do
        expect(scanner.absolutize_key('.title', 'app/views/movies/show.html.slim', %w(app/views))).to eq('movies.show.title')
      end
    end

    context 'custom roots' do
      it 'works' do
        expect(scanner.absolutize_key('.title', 'app/views-mobile/movies/show.html.slim', %w(app/views app/views-mobile))).to eq('movies.show.title')
      end
    end

  end

end
