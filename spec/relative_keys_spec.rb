# coding: utf-8
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

    context 'relative key in controller' do
      it 'works' do
        key = scanner.absolutize_key(
          '.success',
          'app/controllers/users_controller.rb',
          %w(app/controllers),
          'create'
        )

        expect(key).to eq('users.create.success')
      end

      context 'multiple words in controller name' do
        it 'works' do
          key = scanner.absolutize_key(
            '.success',
            'app/controllers/admin_users_controller.rb',
            %w(app/controllers),
            'create'
          )

          expect(key).to eq('admin_users.create.success')
        end
      end

      context 'nested in module' do
        it 'works' do
          key = scanner.absolutize_key(
            '.success',
            'app/controllers/nested/users_controller.rb',
            %w(app/controllers),
            'create'
          )

          expect(key).to eq('nested.users.create.success')
        end
      end
    end

    context 'relative key in mailer' do
      it 'works' do
        key = scanner.absolutize_key(
          '.subject',
          'app/mailers/user_mailer.rb',
          %w(app/mailers),
          'welcome'
        )

        expect(key).to eq('user_mailer.welcome.subject')
      end

      context 'multiple words in mailer name' do
        it 'works' do
          key = scanner.absolutize_key(
            '.subject',
            'app/mailers/admin_user_mailer.rb',
            %w(app/mailers),
            'welcome'
          )

          expect(key).to eq('admin_user_mailer.welcome.subject')
        end
      end

      context 'nested in module' do
        it 'works' do
          key = scanner.absolutize_key(
            '.subject',
            'app/mailers/nested/user_mailer.rb',
            %w(app/mailers),
            'welcome'
          )

          expect(key).to eq('nested.user_mailer.welcome.subject')
        end
      end
    end
  end
end
