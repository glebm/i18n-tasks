class EventComponent < ViewComponent::Base
  def whatever
    t(".key")
    t("absolute_key")
  end
end
