require 'spec_helper'
describe 'Relative keys' do
  let(:task) { I18n::Tasks::BaseTask.new }

  describe 'absolutize_key' do

    context 'default settings' do
      it 'works' do
        task.absolutize_key('.title', 'app/views/movies/show.html.slim').should == 'movies.show.title'
      end
    end

    context 'custom roots' do
      it 'works' do
        task.absolutize_key('.title', 'app/views-mobile/movies/show.html.slim', %w(app/views-mobile)).should == 'movies.show.title'
      end
    end

  end

end
