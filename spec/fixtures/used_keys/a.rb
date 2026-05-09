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
    # Slash notation for nested attributes (issue #702)
    Product.human_attribute_name("status.active")
    # Dynamic argument - cannot be statically resolved, should be skipped without error
    Product.human_attribute_name("status.#{status}")
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

  def scope
    'some.scope'
  end

  def test_dynamic_scope
    # Dynamic scope - cannot be statically resolved, should be skipped
    t('shorthand_scope_key', scope:)
    t('chained_scope_key', scope: f.object.report.model_name.collection)
  end
end
