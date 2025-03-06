# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PrismScanner' do
  describe 'with prism',
           if: I18n::Tasks::Scanners::PrismScanner::PARSER.present? do
    describe 'controllers' do
      it 'detects controller' do
        source = <<~RUBY
          class EventsController < ApplicationController
            before_action(:method_in_before_action1, only: :create)
            before_action('method_in_before_action2', except: %i[create])

            def create
              value = t('.relative_key')
              @key = t('absolute_key')
              some_method || I18n.t('very_absolute_key') && other
              -> { I18n.t('.other_relative_key') }
              method_a
            end

            def custom_action
              value = if this
                t('.relative_key')
              else
                I18n.t('absolute_key')
              end
              method_a
            end

            private

            def method_a
              t('.success')
            end

            def method_in_before_action1
              t('.before_action1')
            end

            def method_in_before_action2
              t('.before_action2')
            end
          end
        RUBY
        occurrences =
          process_string('app/controllers/events_controller.rb', source)
        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            absolute_key
            events.create.relative_key
            events.create.success
            events.create.before_action1
            very_absolute_key
            events.custom_action.relative_key
            events.custom_action.success
            events.custom_action.before_action2
            other_relative_key
          ]
        )
      end

      it 'empty controller' do
        source = <<~RUBY
          class ApplicationController < ActionController::Base
          end
        RUBY
        expect(
          process_string('app/controllers/application_controller.rb', source)
        ).to be_empty
      end

      it 'handles empty method' do
        source = <<~RUBY
          class EventsController < ApplicationController
            def create
            end
          end
        RUBY

        expect(
          process_string('app/controllers/events_controller.rb', source)
        ).to be_empty
      end

      it 'handles call with same name' do
        source = <<~RUBY
          class EventsController < ApplicationController
            def new
              @user = User.new
            end
          end
        RUBY

        expect(
          process_string('app/controllers/events_controller.rb', source)
        ).to be_empty
      end

      it 'handles more syntax' do
        occurrences =
          process_path('./spec/fixtures/prism_controller.rb')

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            prism.prism.index.label
            prism.prism.show.relative_key
            prism.show.assign
            prism.show.multiple
          ]
        )
      end

      it 'handles before_action as lambda' do
        source = <<~RUBY
          class EventsController < ApplicationController
            before_action -> { t('.before_action') }, only: :create
            before_action { non_existent if what? }
            before_action do
              t('.before_action2')
            end

            def create
              t('.relative_key')
            end
          end
        RUBY

        occurrences =
          process_string('app/controllers/events_controller.rb', source)

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[events.create.relative_key events.create.before_action events.create.before_action2]
        )
      end

      it 'errors on cyclic calls' do
        source = <<~RUBY
          class CyclicCallController
            def method_a
              method_b
            end

            def method_b
              method_a
            end
          end
        RUBY

        expect do
          process_string('spec/fixtures/cyclic_call_controller.rb', source)
        end.to raise_error(
          ArgumentError,
          /Cyclic call detected: method_a -> method_b/
        )
      end

      it 'returns nothing if only relative keys and private methods' do
        source = <<~RUBY
          class EventsController
            private

            def method_b
              t('.relative_key')
            end
          end
        RUBY

        expect(
          process_string('app/controllers/events_controller.rb', source)
        ).to be_empty
      end

      it 'detects calls in methods' do
        source = <<~RUBY
          class EventsController
            def create
              t('.relative_key')
              I18n.t("absolute_key")
              method_b
            end

            def method_b
              t('.error')
              t("absolute_error")
            end
          end
        RUBY

        occurrences =
          process_string('app/controllers/events_controller.rb', source)

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            absolute_key
            absolute_error
            events.create.relative_key
            events.create.error
            events.method_b.error
          ]
        )
      end

      it 'handles controller nested in modules' do
        source = <<~RUBY
          module Admin
            class EventsController
              def create
                t('.relative_key')
                I18n.t("absolute_key")
                I18n.t(".relative_key_with_receiver")
              end
            end
          end
        RUBY

        occurrences =
          process_string('app/controllers/admin/events_controller.rb', source)

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            absolute_key
            admin.events.create.relative_key
            relative_key_with_receiver
          ]
        )
      end

      it 'handles controller with namespaced class name' do
        source = <<~RUBY
          class Admins::TestScopes::EventsController
            def create
              t('.relative_key')
              I18n.t("absolute_key")
            end
          end
        RUBY

        occurrences =
          process_string('app/controllers/admin/events_controller.rb', source)

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[absolute_key admins.test_scopes.events.create.relative_key]
        )
      end

      it 'rails model translations' do # rubocop:disable RSpec/MultipleExpectations
        source = <<~RUBY
          Event.human_attribute_name(:title)
          Event.model_name.human(count: 2)
          Event.model_name.human
        RUBY

        occurrences = process_string('app/models/event.rb', source)

        expect(occurrences.map(&:first)).to match_array(
          %w[
            activerecord.attributes.event.title
            activerecord.models.event.one
            activerecord.models.event.other
          ]
        )

        occurrence = occurrences.first.last
        expect(occurrence.raw_key).to eq('activerecord.attributes.event.title')
        expect(occurrence.path).to eq('app/models/event.rb')
        expect(occurrence.line_num).to eq(1)
        expect(occurrence.line).to eq('Event.human_attribute_name(:title)')

        occurrence = occurrences.second.last
        expect(occurrence.raw_key).to eq('activerecord.models.event.other')
        expect(occurrence.path).to eq('app/models/event.rb')
        expect(occurrence.line_num).to eq(2)
        expect(occurrence.line).to eq('Event.model_name.human(count: 2)')

        occurrence = occurrences.last.last
        expect(occurrence.raw_key).to eq('activerecord.models.event.one')
        expect(occurrence.path).to eq('app/models/event.rb')
        expect(occurrence.line_num).to eq(3)
        expect(occurrence.line).to eq('Event.model_name.human')
      end
    end

    describe 'magic comments' do
      it 'i18n-tasks-use' do # rubocop:disable RSpec/MultipleExpectations
        source = <<~'RUBY'
          # i18n-tasks-use t('translation.from.comment')
          SpecialMethod.translate_it
          # i18n-tasks-use t('scoped.translation.key1')
          I18n.t("scoped.translation.#{variable}")

          # i18n-tasks-use t('translation.from.comment2')
          # i18n-tasks-use t('translation.from.comment3')
        RUBY

        occurrences =
          process_string('spec/fixtures/used_keys/app/controllers/a.rb', source)

        expect(occurrences.size).to eq(4)

        expect(occurrences.map(&:first)).to match_array(
          %w[
            translation.from.comment
            scoped.translation.key1
            translation.from.comment2
            translation.from.comment3
          ]
        )

        occurrence = occurrences.find { |key, _| key == 'translation.from.comment' }.last
        expect(occurrence.path).to eq(
          'spec/fixtures/used_keys/app/controllers/a.rb'
        )
        expect(occurrence.line_num).to eq(2)
        expect(occurrence.line).to eq('SpecialMethod.translate_it')

        occurrence = occurrences.find { |key, _| key == 'scoped.translation.key1' }.last
        expect(occurrence.path).to eq(
          'spec/fixtures/used_keys/app/controllers/a.rb'
        )
        expect(occurrence.line_num).to eq(4)
        expect(occurrence.line).to eq(
          "I18n.t(\"scoped.translation.\#{variable}\")"
        )

        occurrence = occurrences.find { |key, _| key == 'translation.from.comment3' }.last
        expect(occurrence.path).to eq(
          'spec/fixtures/used_keys/app/controllers/a.rb'
        )
        expect(occurrence.line_num).to eq(7)
        expect(occurrence.line).to eq(
          "# i18n-tasks-use t('translation.from.comment3')"
        )
      end

      it 'i18n-tasks-skip-prism' do
        scanner =
          I18n::Tasks::Scanners::PrismScanner.new(
            config: {
              relative_roots: ['spec/fixtures/used_keys/app/controllers']
            }
          )

        occurrences =
          scanner.send(
            :scan_file,
            'spec/fixtures/used_keys/app/controllers/events_controller.rb'
          )
        # The `events.method_a.from_before_action` would not be detected by prism
        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            absolute_key
            events.create.relative_key
            events.method_a.from_before_action
            very_absolute_key
          ]
        )
      end
    end

    it 'class' do
      source = <<~RUBY
        class Event
          def what
            t('a')
            t('.relative')
            I18n.t('b')
          end
        end
      RUBY
      occurrences = process_string('app/models/event.rb', source)

      expect(occurrences.map(&:first)).to match_array(%w[a b])

      occurrence = occurrences.first.last
      expect(occurrence.path).to eq('app/models/event.rb')
      expect(occurrence.line_num).to eq(3)
      expect(occurrence.line).to eq('t(\'a\')')

      occurrence = occurrences.last.last

      expect(occurrence.path).to eq('app/models/event.rb')
      expect(occurrence.line_num).to eq(5)
      expect(occurrence.line).to eq("I18n.t('b')")
    end

    it 'file without class' do
      source = <<~RUBY
        t("what.is.this", parameter: I18n.translate("other.thing"))
      RUBY

      occurrences =
        process_string('spec/fixtures/file_without_class.rb', source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[what.is.this other.thing]
      )
    end

    describe 'translation options' do
      it 'handles scope' do
        source = <<~RUBY
          t('scope_string', scope: 'events.descriptions')
          I18n.t('scope_array', scope: ['events', 'titles'])
        RUBY

        occurrences = process_string('scope.rb', source)

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[events.descriptions.scope_string events.titles.scope_array]
        )
      end
    end

    describe 'ruby visitor' do
      it 'ignores controller behaviour' do
        source = <<~RUBY
          class EventsController
            before_action(:method_in_before_action1, only: :create)

            def create
              t('.relative_key')
              I18n.t("absolute_key", wha: 'ever')
              method_b
            end

            def method_b
              t('.error')
              t("absolute_error")
            end

            private

            def method_in_before_action1
              t('.before_action1')
              t("absolute_before_action1")
          end
        RUBY

        occurrences =
          process_string(
            'app/controllers/events_controller.rb',
            source,
            visitor: 'ruby'
          )

        expect(occurrences.map(&:first).uniq).to match_array(
          %w[
            absolute_before_action1
            absolute_error
            absolute_key
          ]
        )
      end
    end
  end

  describe 'without prism',
           if: I18n::Tasks::Scanners::PrismScanner::PARSER.nil? do
    it '#used_keys - fallback to ruby ast parser' do
      scanner =
        I18n::Tasks::Scanners::PrismScanner.new(
          config: {
            relative_roots: ['spec/fixtures/used_keys/app/controllers']
          }
        )

      occurrences =
        scanner.send(
          :scan_file,
          'spec/fixtures/used_keys/app/controllers/events_controller.rb'
        )
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          absolute_key
          events.create.relative_key
          events.method_a.from_before_action
          very_absolute_key
        ]
      )
    end
  end

  def process_path(path)
    I18n::Tasks::Scanners::PrismScanner.new.send(:scan_file, path)
  end

  def process_string(path, string, visitor: 'rails')
    results = I18n::Tasks::Scanners::PrismScanner::PARSER.parse(string)
    I18n::Tasks::Scanners::PrismScanner.new(config: { prism_visitor: visitor }).send(
      :process_results,
      path,
      results
    )
  end
end
