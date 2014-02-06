require 'i18n/tasks/data/file_system'

# older configs may use this
require 'i18n/tasks/data/yaml'

module I18n::Tasks::TranslationData

  # I18n data provider
  # @see I18n::Tasks::Data::Yaml
  def data
    @data ||= data_config[:adapter].constantize.new(data_config[:options])
  end

  # whether the value for key exists in locale (defaults: base_locale)
  def key_value?(key, locale = base_locale)
    t(data[locale], key).present?
  end

  # @return [Array<String>] all available locales
  def locales
    config[:locales] ||= I18n.available_locales.map(&:to_s)
  end

  # @return [String] default i18n locale
  def base_locale
    config[:base_locale] ||= I18n.default_locale.to_s
  end

  def non_base_locales(from = nil)
    from = self.locales unless from.present?
    Array(from) - [base_locale]
  end

  # write to store, normalizing all data
  def normalize_store!(from = nil)
    from = self.locales unless from.present?
    Array(from).each do |target_locale|
      # the store itself handles normalization
      data[target_locale] = data[target_locale]
    end
  end
end
