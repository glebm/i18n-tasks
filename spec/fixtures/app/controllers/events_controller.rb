class EventsController < ApplicationController
  def create
  end

  def show()
    redirect_to :edit, notice: I18n.t('cb.a')

    # args are ignored
    I18n.t("cb.b", i: "Hello")

    # patterns that should not be reported as unused in dynamic mode
    I18n.t("hash.pattern.#{some_value}", i: "Hello")
    I18n.t("hash.pattern2." + some_value, i: "Hello")
    I18n.t "hash.pattern3.#{b.gsub(%r{/{}{}}, x)}.#{c}.z"

    # should not be reported as unused (scope argument support)
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

    # only `t()` calls can use relative keys and not `I18n.t()` calls.
    I18n.t('.not_relative')

    # Nested calls in ruby files should be reported
    I18n.t('nested.parent.rb', x: I18n.t('nested.child.rb'))
  end

  def update
  end
end
