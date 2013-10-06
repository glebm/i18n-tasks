class EventsController < ApplicationController
  def show
    redirect_to :edit, notice: I18n.t('cb.a')
    I18n.t("cb.b", i: "Hello")
    I18n.t("hash_pattern.#{some_value}", i: "Hello")
    I18n.t("hash_pattern2." + some_value, i: "Hello")
    I18n.t "hash_pattern3", scope: "foo.bar"
  end
end
