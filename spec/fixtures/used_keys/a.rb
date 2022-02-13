class A
  def what
    t('a')
  end

  def whot
    I18n.t('a')
  end

  def self.whot
    # i18n-tasks-use t('activerecord.attributes.model.what')
    Model.human_attribute_name(:what)
    I18n.t('activerecord.attributes.model.what')
    translates("activerecord.attributes.model.what")
  end
end
