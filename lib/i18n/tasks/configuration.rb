module I18n::Tasks::Configuration
  extend ActiveSupport::Concern

  # i18n-tasks config (defaults + config/i18n-tasks.yml)
  # @return [Hash{String => String,Hash,Array}]
  def config
    @config ||= I18n::Tasks.config
  end

  DEFAULT_PATTERN = /\bt[( ]\s*(:?".+?"|:?'.+?'|:\w+)/
  # search config
  # @return [Hash{String => String,Hash,Array}]
  def search_config
    @search_config ||= begin
      if config.key?(:grep)
        config[:search] ||= config.delete(:grep)
        I18n::Tasks.warn_deprecated 'please rename "grep" key to "search" in config/i18n-tasks.yml'
      end
      search_config = (config[:search] || {}).with_indifferent_access
      search_config.tap do |conf|
        conf[:paths] = %w(app/) if conf[:paths].blank?
        conf[:include] = Array(conf[:include]) if conf[:include].present?
        conf[:exclude] = Array(conf[:exclude])
        conf[:pattern] = conf[:pattern].present? ? Regexp.new(conf[:pattern]) : DEFAULT_PATTERN
      end
    end
  end

  # translation config
  # @return [Hash{String => String,Hash,Array}]
  def translation_config
    @translation_config ||= begin
      conf           = (config[:translation] ||= {}).with_indifferent_access
      conf[:api_key] ||= ENV['GOOGLE_TRANSLATE_API_KEY']
      conf
    end
  end
end