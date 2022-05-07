class EventsController < ApplicationController
  def create
    t(".relative_key")
    t("absolute_key")
    I18n.t("very_absolute_key")
  end
end
