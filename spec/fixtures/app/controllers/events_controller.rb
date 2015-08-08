class EventsController < ApplicationController
  def create
  end

  def show()
    redirect_to :edit, notice: I18n.t('cb.a')

    # args are ignored
    I18n.t("cb.b", i: "Hello")

    # pattern not reported as unused
    I18n.t("hash.pattern.#{some_value}", i: "Hello")

    # pattern also not reported as unused
    I18n.t("hash.pattern2." + some_value, i: "Hello")

    # same as above but with scope argument
    I18n.t(some_value, scope: [:hash, :pattern3])

    # missing:
    I18n.t 'pattern_missing.a', scope: :hash, other: 1

    # missing:
    I18n.t :b, scope: [:hash, :pattern_missing], other: 1

    # missing, but not yet detected as such :(
    I18n.t "#{stuff}.pattern_missing.c"

    # not missing
    I18n.t "hash.#{stuff}.a"

    # relative key
    t(".success")

    # i18n-tasks-use t('magic_comment')
    magic

    # default arg
    I18n.t('default_arg', default: 'Default Text')
  end

  def update
  end
end
