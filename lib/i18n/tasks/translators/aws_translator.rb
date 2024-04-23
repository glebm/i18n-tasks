# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'

module I18n::Tasks::Translators
  class AwsTranslator < BaseTranslator
    def initialize(*)
      begin
        require 'aws-sdk-translate'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'aws-sdk-translate' to your Gemfile to use this command"
      end
      super
    end

    protected

    def translate_values(list, **options)
      list.map do |str| 
        aws_translate_client.translate_text(
          options.merge( text: str )
        ).translated_text
      end
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        source_language_code: from,
        target_language_code: to,
      )
    end

    def options_for_html
      {}
    end

    def options_for_plain
      {}
    end

    def no_results_error_message
      I18n.t('i18n_tasks.aws_translate.errors.no_results')
    end

    private

    def aws_translate_client
      @aws_translate_client ||= Aws::Translate::Client.new(region: region, credentials: credentials)
    end

    def region
      @region ||= @i18n_tasks.translation_config[:aws_region]
    end

    def credentials
      @credentials ||= begin
                         aws_access_key_id = @i18n_tasks.translation_config[:aws_access_key_id]
                         aws_secret_access_key = @i18n_tasks.translation_config[:aws_secret_access_key]
                         fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.aws_translate.errors.no_api_key') if aws_access_key_id.blank? || aws_secret_access_key.blank?
                         Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
                       end
    end
  end
end
