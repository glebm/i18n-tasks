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

  def ignore_config(type = nil)
    key = type ? "ignore_#{type}" : 'ignore'
    @config_sections[key] ||= config[key]
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
    [nil, :missing, :unused, :eq_base].each do |ignore_type|
      ignore_config ignore_type
    end
    @config_sections
  end

  def config_for_inspect
    to_hash_from_indifferent(config_sections.reject { |k, v| v.blank? }).tap do |sections|
      sections.each do |_k, section|
        section.merge! section.delete('config') if Hash === section && section.key?('config')
      end
    end
  end

  private

  def to_hash_from_indifferent(v)
    case v
      when Hash
        v.stringify_keys.to_hash.tap do |h|
          h.each { |k, v| h[k] = to_hash_from_indifferent(v) if Hash === v || Array === v }
        end
      when Array
        v.map { |e| to_hash_from_indifferent e }
      else
        v
    end
  end
end
