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
  def key_value?(key, locale = base_locale)
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

  # write to store, normalizing all data
  def normalize_store!(locales = self.locales)
    Array(locales).each do |target_locale|
      # the store itself handles normalization
      data[target_locale] = data[target_locale]
    end
  end

  # fill missing / blank keys with values from passed block
  def fill_blanks!(locale = base_locale, &fill_with)
    blank_keys =
        if locale == base_locale
          # for base locale "blank" is: present in source but not in the base locale.
          keys_missing_base_value.map { |e| e[:key] } +
              traverse_flat_map(data[base_locale]) { |key, value|
                key if value.to_s.blank? && !ignore_key?(key, :missing) }
        else
          # for other locales "blank" is: present in base but not in the locale itself.
          traverse_flat_map(data[base_locale]) { |key|
            key if !key_value?(key, locale) && !ignore_key?(key, :missing) }
        end

    list         = blank_keys.uniq.zip fill_with.call(blank_keys)
    data[locale] = data[locale].deep_merge(list_to_tree(list))
  end
end