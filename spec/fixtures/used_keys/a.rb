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
    Archive.human_attribute_name(:name)
    User.model_name.human(count: 2)
    # Cannot infer the type
    human_attribute_name(:name)
    model_name.human(count: 2)
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
