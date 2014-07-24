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
    config = file && YAML.load(Erubis::Eruby.new(File.read(file)).result)
    if config.present?
      config.with_indifferent_access.tap do |c|
        if c[:relative_roots]
          warn_deprecated 'config/i18n-tasks.yml has relative_roots on top level. Please move relative_roots under search.'
          c[:search][:relative_roots] = c.delete(:relative_roots)
        end
      end
    else
      {}.with_indifferent_access
    end
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
    @config_sections[:locales] ||= data.locales
  end

  # @return [String] default i18n locale
  def base_locale
    @config_sections[:base_locale] ||= (config[:base_locale] || 'en').to_s
  end


  def ignore_config(type = nil)
    key = type ? "ignore_#{type}" : 'ignore'
    @config_sections[key] ||= config[key]
  end

  IGNORE_TYPES = [nil, :missing, :unused, :eq_base].freeze
  # evaluated configuration (as the app sees it)
  def config_sections
    # init all sections
    base_locale
    locales
    data_config
    search_config
    translation_config
    IGNORE_TYPES.each do |ignore_type|
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
