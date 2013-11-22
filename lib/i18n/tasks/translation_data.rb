require 'i18n/tasks/data_traversal'
require 'i18n/tasks/data/yaml'

module I18n::Tasks::TranslationData
  include I18n::Tasks::DataTraversal

  # I18n data provider
  # @see I18n::Tasks::Data::Yaml
  def data
    return @data if @data
    conf    = (config[:data] || {}).with_indifferent_access
    adapter = (conf[:adapter].presence || conf[:class].presence || :yaml).to_s
    if adapter !~ /[A-Z]/
      adapter = "I18n::Tasks::Data::#{adapter.camelize}"
    end
    @data = adapter.constantize.new(conf.except(:adapter, :class))
  end

  # whether the value for key exists in locale (defaults: base_locale)
  def key_has_value?(key, locale = base_locale)
    t(data[locale], key).present?
  end

  # @return [String] default i18n locale
  def base_locale
    config[:base_locale] ||= I18n.default_locale.to_s
  end

  # @return [Array<String>] all available locales
  def locales
    config[:locales] ||= I18n.available_locales.map(&:to_s)
  end
end