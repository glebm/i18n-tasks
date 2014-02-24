module I18n::Tasks::Configuration
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
      adapter = (conf[:adapter].presence || conf[:class].presence || :file_system).to_s
      if adapter !~ /[A-Z]/
        adapter = "I18n::Tasks::Data::#{adapter.camelize}"
      end
      {adapter: adapter, options: conf.except(:adapter, :class)}
    end
  end

  def relative_roots
    @config_sections[:relative_roots] ||= config[:relative_roots].presence || %w(app/views)
  end

  # translation config
  # @return [Hash{String => String,Hash,Array}]
  def translation_config
    @config_sections[:translation] ||= begin
      conf           = (config[:translation] || {}).with_indifferent_access
      conf[:api_key] ||= ENV['GOOGLE_TRANSLATE_API_KEY']
      conf
    end
  end
end
