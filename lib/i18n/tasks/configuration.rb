# coding: utf-8
module I18n::Tasks::Configuration
  # i18n-tasks config (defaults + config/i18n-tasks.yml)
  # @return [Hash{String => String,Hash,Array}]
  def config
    @config || (self.config = {})
  end

  CONFIG_FILES = %w(
      config/i18n-tasks.yml config/i18n-tasks.yml.erb
      i18n-tasks.yml i18n-tasks.yml.erb
  )

  def file_config
    file = CONFIG_FILES.detect { |f| File.exists?(f) }
    file = YAML.load(Erubis::Eruby.new(File.read(file)).result) if file
    {}.with_indifferent_access.merge(file.presence || {})
  end

  def config=(conf)
    @config          = file_config.deep_merge(conf)
    @config_sections = {}
    @config
  end

  # data config
  #  @return [{adapter: String, options: Hash}]
  def data_config
    @config_sections[:data] ||= begin
      {
          adapter: data.class.name,
          config:  data.config
      }
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
      conf[:api_key] ||= ENV['GOOGLE_TRANSLATE_API_KEY'] if ENV.key?('GOOGLE_TRANSLATE_API_KEY')
      conf
    end
  end

  def search_config
    @config_sections[:search] ||= {
        scanner: scanner.class.name,
        config:  scanner.config
    }
  end

  # @return [Array<String>] all available locales, base_locale is always first
  def locales
    @config_sections[:locales] ||= begin
      locales = config[:locales]
      locales ||= data.available_locales
      locales = locales.map(&:to_s)
      locales = if locales.include?(base_locale)
                  [base_locale] + (locales - [base_locale])
                else
                  [base_locale] + locales
                end
      if config[:locales]
        log_verbose "config.locales set to #{locales}"
      else
        log_verbose "config.locales inferred from data #{locales}"
      end
      locales
    end
  end

  def non_base_locales(from = nil)
    from ||= self.locales
    Array(from) - [base_locale]
  end

  # @return [String] default i18n locale
  def base_locale
    @config_sections[:base_locale] ||= (config[:base_locale] || 'en').to_s
  end

  # evaluated configuration (as the app sees it)
  def config_sections
    # init all sections
    base_locale
    locales
    data_config
    search_config
    relative_roots
    translation_config
    @config_sections
  end

  def config_for_inspect
    # hide empty sections, stringify keys
    Hash[config_sections.reject { |k, v| v.empty? }.map { |k, v|
      [k.to_s, v.respond_to?(:stringify_keys) ? v.stringify_keys : v] }].tap do |h|
      h.each do |_k, v|
        if v.is_a?(Hash) && v.key?('config')
          v.merge! v.delete('config')
        end
      end
    end
  end
end
