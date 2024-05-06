# frozen_string_literal: true

class EventsController < ApplicationController
  before_action(:method_in_before_action, only: :create)
  before_action('method_in_before_action2', except: %i[create])

  def create
    t('.relative_key')
    t('absolute_key')
    I18n.t('very_absolute_key')
    method_a
  end

  def not_an_action
    t('.relative_key')
    method_a
  end

  private

  def method_a
    t('.success')
  end

  def method_in_before_action
    t('.before_action')
  end

  def method_in_before_action2
    t('.before_action2')
  end
end
