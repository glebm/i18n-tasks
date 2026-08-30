# frozen_string_literal: true

require "i18n/tasks/translators/openai_translator"

module I18n::Tasks::Translators
  # Translates via OrcaRouter (https://www.orcarouter.ai), an OpenAI-compatible
  # AI gateway. Reuses the OpenAI translation flow, pointing the client at the
  # OrcaRouter endpoint.
  class OrcaRouterTranslator < OpenAiTranslator
    URI_BASE = "https://api.orcarouter.ai/v1"

    def no_results_error_message
      I18n.t("i18n_tasks.orcarouter_translate.errors.no_results")
    end

    private

    def translator
      @translator ||= OpenAI::Client.new(access_token: api_key, uri_base: URI_BASE, log_errors: true)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:orcarouter_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t("i18n_tasks.orcarouter_translate.errors.no_api_key") if key.blank?

        key
      end
    end

    def model
      @model ||= @i18n_tasks.translation_config[:orcarouter_model].presence || "orcarouter/fusion"
    end

    def temperature
      @temperature ||= @i18n_tasks.translation_config[:orcarouter_temperature].presence || 0.0
    end

    def system_prompt(to_locale)
      prompt = if locale_prompts[to_locale].present?
        locale_prompts[to_locale]
      else
        @i18n_tasks.translation_config[:orcarouter_system_prompt].presence || DEFAULT_SYSTEM_PROMPT
      end

      prompt.concat("\n#{JSON_FORMAT_INSTRUCTIONS_SYSTEM_PROMPT}")
    end

    def locale_prompts
      @locale_prompts ||= @i18n_tasks.translation_config[:orcarouter_locale_prompts] || {}
    end
  end
end
