require 'i18n/tasks/data/yaml'

module I18n::Tasks::TranslationData
  # locale data hash, with locale name as root
  # @return [Hash{String => String,Hash}] locale data in nested hash format
  def locale_data(locale)
    locale                        = locale.to_s
    (@locale_data ||= {})[locale] ||= data_source.get(locale) || {}
  end

  # I18n data provider
  def data_source
    return @source if @source
    conf    = (config[:data] || {}).with_indifferent_access
    adapter = (conf[:adapter].presence || conf[:class].presence || :yaml).to_s
    if adapter !~ /[A-Z]/
      adapter = "I18n::Tasks::Data::#{adapter.camelize}"
    end
    @source = adapter.constantize.new(conf.except(:adapter, :class))
  end

  # translation of the key found in the passed hash or nil
  # @return [String,nil]
  def t(hash, key)
    key.split('.').inject(hash) { |r, seg| r[seg] if r }
  end

  # traverse hash, yielding with full key and value
  # @param hash [Hash{String => String,Hash}] translation data to traverse
  # @yield [full_key, value] yields full key and value for every translation in #hash
  # @return [nil]
  def traverse(path = '', hash)
    q = [[path, hash]]
    until q.empty?
      path, value = q.pop
      if value.is_a?(Hash)
        value.each { |k, v| q << ["#{path}.#{k}", v] }
      else
        yield path[1..-1], value
      end
    end
  end

  # @return [String] default i18n locale
  def base_locale
    I18n.default_locale.to_s
  end

  # @return [Hash{String => String,Hash}] default i18n locale data
  def base_locale_data
    locale_data(base_locale)[base_locale]
  end

  # whether the value for key exists in locale (defaults: base_locale)
  def key_has_value?(key, locale = base_locale)
    t(locale_data(locale)[locale], key).present?
  end
end