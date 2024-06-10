# i18n-tasks-skip-prism
class EventsController < ApplicationController
  before_action(:method_a)
  def create
    t(".relative_key")
    t("absolute_key")
    I18n.t("very_absolute_key")
  end

  private

  def method_a
    t(".from_before_action")
  end
end
