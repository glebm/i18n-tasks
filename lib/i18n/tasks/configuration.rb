module I18n::Tasks::Configuration
  extend ::ActiveSupport::Concern

  # i18n-tasks config (defaults + config/i18n-tasks.yml)
  # @return [Hash{String => String,Hash,Array}]
  def config
    @config || (self.config = {})
  end

  def config=(conf)
    @config          = I18n::Tasks.config.deep_merge(conf)
    @config_sections = {}
    @config
  end

  # data config
  #  @return [{adapter: String, options: Hash}]
  def data_config
    @config_sections[:data] ||= begin
      conf    = (config[:data] || {}).with_indifferent_access
      adapter = (conf[:adapter].presence || conf[:class].presence || :yaml).to_s
      if adapter !~ /[A-Z]/
        adapter = "I18n::Tasks::Data::#{adapter.camelize}"
      end
      {adapter: adapter, options: conf.except(:adapter, :class)}
    end
  end

  DEFAULT_PATTERN = /\bt(?:ranslate)?[( ]\s*(:?".+?"|:?'.+?'|:\w+)/
  # search config
  # @return [Hash{String => String,Hash,Array}]
  def search_config
    @config_sections[:search] ||= begin
      if config.key?(:grep)
        config[:search] ||= config.delete(:grep)
        I18n::Tasks.warn_deprecated 'please rename "grep" key to "search" in config/i18n-tasks.yml'
      end
      search_config = (config[:search] || {}).with_indifferent_access
      search_config.tap do |conf|
        conf[:paths]   = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude])
        conf[:pattern] = conf[:pattern].present? ? Regexp.new(conf[:pattern]) : DEFAULT_PATTERN
      end
    end
  end

  def relative_roots
    @config_sections[:relative_roots] ||= config[:relative_roots].presence || %w(app/views)
  end

  def relative_roots=(paths)
    @config_sections[:relative_roots] = paths
  end

  # translation config
  # @return [Hash{String => String,Hash,Array}]
  def translation_config
    @config_sections[:translation] ||= begin
      conf           = (config[:translation] ||= {}).with_indifferent_access
      conf[:api_key] ||= ENV['GOOGLE_TRANSLATE_API_KEY']
      conf
    end
  end
end
