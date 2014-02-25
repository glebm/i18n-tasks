class EventsController < ApplicationController
  def show
    redirect_to :edit, notice: I18n.t('cb.a')
    I18n.t("cb.b", i: "Hello")
    I18n.t("hash.pattern.#{some_value}", i: "Hello")
    I18n.t("hash.pattern2." + some_value, i: "Hello")

    # missing:
    I18n.t "pattern2.m", scope: :hash, c: 1

    # missing:
    I18n.t "pattern3.m", scope: :hash, c: 1

    # not missing
    I18n.t "#{stuff}.a", scope: :hash, c: 1

    # missing, but not yet detected as such :(
    I18n.t "hash.#{stuff}.c"
  end
end
