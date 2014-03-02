require 'i18n/tasks/data/file_system'

module I18n::Tasks::Data
  # I18n data provider
  # @see I18n::Tasks::Data::FileSystem
  def data
    @data ||= begin
      conf    = (config[:data] || {}).with_indifferent_access
      adapter = (conf[:adapter].presence || conf[:class].presence || :file_system).to_s
      if adapter !~ /[A-Z]/
        adapter = "I18n::Tasks::Data::#{adapter.camelize}"
      end
      adapter.constantize.new(conf.except(:adapter, :class))
    end
  end

  def t(key, locale = base_locale)
    data.t(key, locale)
  end

  def t_proc(locale = base_locale)
    @t_proc         ||= {}
    @t_proc[locale] ||= proc { |key| t(key, locale) }
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

  # if :locales option present, call update_locale_data for each locale
  # otherwise, call update_locale_data for :locale option or base locale
  # @option opts [Array] :locales
  # @option opts [String] :locale
  def update_data(opts = {})
    if opts.key?(:locales)
      locales = (Array(opts[:locales]).presence || self.locales).map(&:to_s)
      # make sure base_locale always comes first if present
      locales = [base_locale] + (locales - [base_locale]) if locales.include?(base_locale)
      opts    = opts.except(:locales)
      locales.each { |locale| update_locale_data(locale, opts.merge(locale: locale)) }
    else
      update_locale_data(opts[:locale] || base_locale, opts)
    end
  end

  # @param locale
  # @option opts [Array|Proc] :keys keys to update, if proc call with locale
  # @option opts [String|Proc] value, if proc call with each key
  # @option opts [String|Proc] values, if proc call with all the keys
  def update_locale_data(locale, opts = {})
    keys = opts[:keys]
    keys = keys.call(locale) if keys.respond_to?(:call)
    return if keys.empty?

    values = opts[:values]
    values = values.call(keys, locale) if values.respond_to?(:call)
    values ||= begin
      value = opts[:value] or raise 'pass value or values'
      if value.respond_to?(:call)
        keys.map { |key| value.call(key, locale) }
      else
        [value] * keys.size
      end
    end
    data[locale] += keys.map(&:to_s).zip(values)
  end

end
