# frozen_string_literal: true

require "spec_helper"

RSpec.describe "PrismScanner" do
  describe "controllers" do
    it "detects controller" do
      source = <<~RUBY
        class EventsController < ApplicationController
          before_action(:method_in_before_action1, only: :create)
          before_action('method_in_before_action2', except: %i[create])

          rescue_from(ActiveRecord::RecordNotFound) do |error|
            redirect_to(root_path, alert: t("controllers.record_not_found"))
          end

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
              ::I18n.t('absolute_key2')
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
        process_string("app/controllers/events_controller.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          absolute_key
          absolute_key2
          controllers.record_not_found
          events.create.before_action1
          events.create.relative_key
          events.create.success
          events.custom_action.before_action2
          events.custom_action.relative_key
          events.custom_action.success
          other_relative_key
          very_absolute_key
        ]
      )
    end

    it "controller - relative key" do
      source = <<~RUBY
        class EventsController < ApplicationController
          def create
            t('.relative_key')
          end
        end
      RUBY

      occurrences =
        process_string("app/controllers/events_controller.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array( # rubocop:disable Performance/ChainArrayAllocation
        %w[events.create.relative_key]
      )

      # Check candidate_keys
      expect(occurrences.map { |o| o.last.candidate_keys }.flatten.uniq).to match_array( # rubocop:disable Performance/ChainArrayAllocation
        %w[
          events.create.relative_key
          events.relative_key
        ]
      )
    end

    it "empty controller" do
      source = <<~RUBY
        class ApplicationController < ActionController::Base
        end
      RUBY
      expect(
        process_string("app/controllers/application_controller.rb", source)
      ).to be_empty
    end

    it "handles empty method" do
      source = <<~RUBY
        class EventsController < ApplicationController
          def create
          end
        end
      RUBY

      expect(
        process_string("app/controllers/events_controller.rb", source)
      ).to be_empty
    end

    it "handles call with same name" do
      source = <<~RUBY
        class EventsController < ApplicationController
          def new
            @user = User.new
          end
        end
      RUBY

      expect(
        process_string("app/controllers/events_controller.rb", source)
      ).to be_empty
    end

    it "handles more syntax" do
      occurrences =
        process_path("./spec/fixtures/prism_controller.rb")

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          prism.prism.index.label
          prism.prism.show.relative_key
          prism.show.assign
          prism.show.multiple
        ]
      )
    end

    it "handles before_action as lambda" do
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
        process_string("app/controllers/events_controller.rb", source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[events.create.relative_key events.create.before_action events.create.before_action2]
      )
    end

    it "handles translation as argument" do
      source = <<~RUBY
        class EventsController < ApplicationController
          def show
            link_to(path, title: t(".edit"))
          end
        end
      RUBY

      occurrences =
        process_string("app/controllers/events_controller.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[events.show.edit]
      )
    end

    it "handles translation inside block" do
      source = <<~RUBY
        class EventsController < ApplicationController
          def show
            component.title { t('.edit') }
          end
        end
      RUBY

      occurrences =
        process_string("app/controllers/events_controller.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[events.show.edit]
      )
    end

    it "handles translation inside proc" do
      source = <<~RUBY
        class Parser
          DEFAULT_ERROR = proc do |invalid, valid|
            I18n.t("i18n_tasks.cmd.enum_opt.invalid", invalid: invalid, valid: valid * ", ")
          end
        end
      RUBY

      occurrences =
        process_string("lib/i18n/tasks/command/option_parsers/enum.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[i18n_tasks.cmd.enum_opt.invalid]
      )
    end

    it "skips translations from cyclic calls" do
      # When parsing it will handle method_a calling method_b and its relative translations
      # but when parsing method_b and seeing method_a would be a cycle, it will skip it
      source = <<~RUBY
        class CyclicCallController
          def method_a
            t('.relative_key_a')
            method_b
          end

          def method_b
            t('.relative_key_b')
            method_a
          end
        end
      RUBY

      occurrences = process_string("spec/fixtures/cyclic_call_controller.rb", source)
      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          cyclic_call.method_a.relative_key_a
          cyclic_call.method_a.relative_key_b
          cyclic_call.method_b.relative_key_b
        ]
      )
    end

    it "returns nothing if only relative keys and private methods" do
      source = <<~RUBY
        class EventsController
          private

          def method_b
            t('.relative_key')
          end
        end
      RUBY

      expect(
        process_string("app/controllers/events_controller.rb", source)
      ).to be_empty
    end

    it "detects calls in methods" do
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
        process_string("app/controllers/events_controller.rb", source)

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

    it "handles controller nested in modules" do
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
        process_string("app/controllers/admin/events_controller.rb", source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          absolute_key
          admin.events.create.relative_key
          relative_key_with_receiver
        ]
      )
    end

    it "handles controller with namespaced class name" do
      source = <<~RUBY
        class Admins::TestScopes::EventsController
          def create
            t('.relative_key')
            I18n.t("absolute_key")
          end
        end
      RUBY

      occurrences =
        process_string("app/controllers/admin/events_controller.rb", source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[absolute_key admins.test_scopes.events.create.relative_key]
      )
    end

    it "rails - model_name.human" do # rubocop:disable RSpec/MultipleExpectations
      source = <<~RUBY
        Event.model_name.human(count: 2)
        Event.model_name.human
        Participant.model_name.human(count: :other)
        Participant.model_name.human(count: :random_key_becomes_plural)
        object.class.model_name.human(count: 2)
      RUBY

      occurrences = process_string("app/lib/script.rb", source)

      expect(occurrences.map(&:first)).to match_array(
        %w[
          activerecord.models.event.one
          activerecord.models.event.other
          activerecord.models.participant.other
          activerecord.models.participant.other
        ]
      )

      occurrence = occurrences[0].last
      expect(occurrence.raw_key).to eq("activerecord.models.event.other")
      expect(occurrence.path).to eq("app/lib/script.rb")
      expect(occurrence.line_num).to eq(1)
      expect(occurrence.line).to eq("Event.model_name.human(count: 2)")
      expect(occurrence.candidate_keys).to eq(
        ["activerecord.models.event.other", "activerecord.models.event"]
      )

      occurrence = occurrences[1].last
      expect(occurrence.raw_key).to eq("activerecord.models.event.one")
      expect(occurrence.path).to eq("app/lib/script.rb")
      expect(occurrence.line_num).to eq(2)
      expect(occurrence.line).to eq("Event.model_name.human")

      occurrence = occurrences[2].last
      expect(occurrence.raw_key).to eq("activerecord.models.participant.other")
      expect(occurrence.path).to eq("app/lib/script.rb")
      expect(occurrence.line_num).to eq(3)
      expect(occurrence.line).to eq("Participant.model_name.human(count: :other)")

      occurrence = occurrences[3].last
      expect(occurrence.raw_key).to eq("activerecord.models.participant.other")
      expect(occurrence.path).to eq("app/lib/script.rb")
      expect(occurrence.line_num).to eq(4)
      expect(occurrence.line).to eq("Participant.model_name.human(count: :random_key_becomes_plural)")
    end

    it "rails - human_attribute_name" do
      source = <<~RUBY
        Event.human_attribute_name(:title)
        Event.human_attribute_name('title')
        Participant.human_attribute_name(:status)
        human_attribute_name(:no_class)
      RUBY

      occurrences = process_string("app/lib/script.rb", source)

      expect(occurrences.map(&:first)).to match_array(
        %w[
          activerecord.attributes.event.title
          activerecord.attributes.event.title
          activerecord.attributes.participant.status
        ]
      )

      occurrence = occurrences[0].last
      expect(occurrence.raw_key).to eq("activerecord.attributes.event.title")
      expect(occurrence.candidate_keys).to eq(
        ["activerecord.attributes.event.title", "attributes.title"]
      )
    end

    it "rails - model methods - inside the class" do
      source = <<~RUBY
        class Event < ApplicationRecord
          def to_s
            model_name.human(count: 1)
            model_name.human(count: :other)
            self.class.model_name.human(count: 2)
          end

          def category
            human_attribute_name(:category) || self.class.human_attribute_name(:category)
          end

          def other_method
            translation = Participant.human_attribute_name(:status)
            Participant.model_name.human(count: 1)
          end

          def key
            :category
          end

          def value
            human_attribute_name(key)
          end
        end
      RUBY

      occurrences = process_string("app/models/event.rb", source)

      expect(occurrences.map(&:first)).to match_array(
        %w[
          activerecord.models.event.one
          activerecord.models.event.other
          activerecord.models.event.other
          activerecord.attributes.event.category
          activerecord.attributes.event.category
          activerecord.attributes.participant.status
          activerecord.models.participant.one
        ]
      )

      occurrence = occurrences[0].last
      expect(occurrence.raw_key).to eq("activerecord.models.event.one")
      expect(occurrence.path).to eq("app/models/event.rb")
      expect(occurrence.line_num).to eq(3)
      expect(occurrence.line).to eq("model_name.human(count: 1)")

      occurrence = occurrences[1].last
      expect(occurrence.raw_key).to eq("activerecord.models.event.other")
      expect(occurrence.path).to eq("app/models/event.rb")
      expect(occurrence.line_num).to eq(4)
      expect(occurrence.line).to eq("model_name.human(count: :other)")

      occurrence = occurrences[4].last
      expect(occurrence.raw_key).to eq("activerecord.attributes.event.category")
      expect(occurrence.path).to eq("app/models/event.rb")
      expect(occurrence.line_num).to eq(9)
      expect(occurrence.line).to eq("self.class.human_attribute_name(:category)")
    end
  end

  describe "mailers" do
    it "detects mailer" do
      source = <<~RUBY
        class UserMailer < ApplicationMailer
          def welcome_email(user)
            @user = user
            # Make sure it does not expect `.subject` from this method
            mail(to: @user.email, subject: t('.subject_with_other_key'))
          end

          def notification_email(user)
            @user = user
            mail(to: @user.email, subject: default_i18n_subject)
          end

          def other_email(user)
            mail(to: user.email)
          end
        end
      RUBY

      occurrences =
        process_string("app/mailers/user_mailer.rb", source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          user_mailer.notification_email.subject
          user_mailer.other_email.subject
          user_mailer.welcome_email.subject_with_other_key
        ]
      )
    end
  end

  describe "magic comments" do
    it "i18n-tasks-use" do
      source = <<~'RUBY'
        # i18n-tasks-use t('translation.from.comment')
        SpecialMethod.translate_it
        # i18n-tasks-use t('scoped.translation.key1')
        I18n.t("scoped.translation.#{variable}")

        # i18n-tasks-use t('translation.from.comment2')
        # i18n-tasks-use t('translation.from.comment3')
      RUBY

      occurrences =
        process_string("spec/fixtures/used_keys/app/controllers/a.rb", source)

      expect(occurrences.size).to eq(4)

      expect(occurrences.map(&:first)).to match_array(
        %w[
          translation.from.comment
          scoped.translation.key1
          translation.from.comment2
          translation.from.comment3
        ]
      )

      occurrence = occurrences.find { |key, _| key == "translation.from.comment" }.last
      expect(occurrence.path).to eq(
        "spec/fixtures/used_keys/app/controllers/a.rb"
      )
      expect(occurrence.line_num).to eq(2)
      expect(occurrence.line).to eq("SpecialMethod.translate_it")

      occurrence = occurrences.find { |key, _| key == "scoped.translation.key1" }.last
      expect(occurrence.path).to eq(
        "spec/fixtures/used_keys/app/controllers/a.rb"
      )
      expect(occurrence.line_num).to eq(4)
      expect(occurrence.line).to eq(
        "I18n.t(\"scoped.translation.\#{variable}\")"
      )

      occurrence = occurrences.find { |key, _| key == "translation.from.comment3" }.last
      expect(occurrence.path).to eq(
        "spec/fixtures/used_keys/app/controllers/a.rb"
      )
      expect(occurrence.line_num).to eq(4)
      expect(occurrence.line).to eq(
        "I18n.t(\"scoped.translation.\#{variable}\")"
      )
    end

    it "i18n-tasks-skip-prism" do
      scanner =
        I18n::Tasks::Scanners::RubyScanner.new(
          config: {
            prism: "rails",
            relative_roots: ["spec/fixtures/used_keys/app/controllers"]
          }
        )

      occurrences =
        scanner.send(
          :scan_file,
          "spec/fixtures/used_keys/app/controllers/events_controller.rb"
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

  it "class" do
    source = <<~RUBY
      class Event
        def what
          t('a')
          t('.relative')
          I18n.t('b')
        end
      end
    RUBY
    occurrences = process_string("app/models/event.rb", source)

    expect(occurrences.map(&:first)).to match_array(%w[a b])

    occurrence = occurrences.first.last
    expect(occurrence.path).to eq("app/models/event.rb")
    expect(occurrence.line_num).to eq(3)
    expect(occurrence.line).to eq("t('a')")

    occurrence = occurrences.last.last

    expect(occurrence.path).to eq("app/models/event.rb")
    expect(occurrence.line_num).to eq(5)
    expect(occurrence.line).to eq("I18n.t('b')")
  end

  it "file without class" do
    source = <<~RUBY
      t("what.is.this", parameter: I18n.translate("other.thing"))
    RUBY

    occurrences =
      process_string("spec/fixtures/file_without_class.rb", source)

    expect(occurrences.map(&:first).uniq).to match_array(
      %w[what.is.this other.thing]
    )
  end

  describe "translation options" do
    it "handles scope" do
      source = <<~RUBY
        scope = 'special.events'
        # These should be detected
        t('scope_string', scope: 'events.descriptions')
        I18n.t('scope_array', scope: ['events', 'titles'])
        I18n.t("scope_array_symbol", scope: %i[events descriptions])
        I18n.t("scope_array_words", scope: %w[events descriptions])

        # Cannot handle, should ignore
        I18n.t("scope_with_known_variable", scope: ["this", "that", scope])
        I18n.t("scope_with_unknown", scope: ["this", "that", unknown, "other"])
        I18n.t(model.key, **translation_options(model))
        I18n.t("success", scope: scope)
      RUBY

      occurrences = process_string("scope.rb", source)

      expect(occurrences.map(&:first).uniq).to match_array(
        %w[
          events.descriptions.scope_string
          events.titles.scope_array
          events.descriptions.scope_array_symbol
          events.descriptions.scope_array_words
        ]
      )
    end
  end

  describe "ruby visitor" do
    it "ignores controller behaviour" do
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
          "app/controllers/events_controller.rb",
          source,
          visitor: "ruby"
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

  def process_path(path, visitor: "rails")
    I18n::Tasks::Scanners::RubyScanner.new(config: {prism: visitor}).send(:scan_file, path)
  end

  def process_string(path, string, visitor: "rails")
    results = Prism.parse(string)
    I18n::Tasks::Scanners::RubyScanner.new(config: {prism: visitor}).send(
      :process_prism_results,
      path,
      results
    )
  end
end
