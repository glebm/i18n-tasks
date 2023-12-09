class UserMailer < ApplicationMailer
  def welcome_notification
    I18n.with_locale(:en) do
      mail subject: default_i18n_subject
    end
  end
end
