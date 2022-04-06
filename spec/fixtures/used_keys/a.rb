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

  SCOPE_CONSTANT = 'path.in.translation.file'.freeze
  def issue441
    t('ignore_a', scope: SCOPE_CONSTANT)
    t('ignore_b', scope: SCOPE_CONSTANT)
  end

  def issue444
    t('ignore_array', scope: [:ignore, SCOPE_CONSTANT])
  end
end
