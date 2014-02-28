require 'i18n/tasks/data/file_system'

module I18n::Tasks::Data
  # I18n data provider
  # @see I18n::Tasks::Data::FileSystem
  def data
    @data ||= data_config[:adapter].constantize.new(data_config[:options])
  end

  def t(key, locale = base_locale)
    data.t(key, locale)
  end

  def t_proc(locale = base_locale)
    @t_proc ||= {}
    @t_proc[locale] ||= proc { |key| t(key, locale)}
  end

  # whether the value for key exists in locale (defaults: base_locale)
  def key_value?(key, locale = base_locale)
    t(key, locale).present?
  end

  # write to store, normalizing all data
  def normalize_store!(from = nil)
    from = self.locales unless from
    Array(from).each do |target_locale|
      # the store itself handles normalization
      data[target_locale] = data[target_locale]
    end
  end

  # @param locales
  # @param locale
  # @param keys
  # @param value
  # @param values
  def update_data(opts = {})
    if opts.key?(:locales)
      locales = (Array(opts[:locales]).presence || self.locales).map(&:to_s)
      # make sure base_locale always comes first if present
      locales = [base_locale] + (locales - [base_locale]) if locales.include?(base_locale)
      opts    = opts.except(:locales)
      locales.each { |locale| update_data(opts.merge(locale: locale)) }
      return
    end
    locale = opts[:locale] || base_locale
    keys   = opts[:keys]
    keys   = keys.call(locale) if keys.respond_to?(:call)
    return if keys.empty?
    values = opts[:values]
    values = values.call(keys, locale) if values.respond_to?(:call)
    unless values
      value  = opts[:value]
      values = if value.respond_to?(:call)
                 keys.map { |key| value.call(key, locale) }
               else
                 [value] * keys.size
               end
    end
    data[locale] = data[locale].merge(LocaleTree.new(locale, keys.map(&:to_s).zip(values)))
  end
end
