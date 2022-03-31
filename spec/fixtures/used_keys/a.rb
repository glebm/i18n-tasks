class A
  def what
    t('a')
  end

  def whot
    I18n.t('a')
  end

  def self.whot
    # i18n-tasks-use t('service.what')
    Service.translate(:what)
    I18n.t('activerecord.attributes.absolute.attribute')
    translate('activerecord.attributes.absolute.attribute')
  end
end
