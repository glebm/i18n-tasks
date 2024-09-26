# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'
require 'active_support/core_ext/string/filters'

module I18n::Tasks::Translators
  class WatsonxTranslator < BaseTranslator
    # max allowed texts per request
    BATCH_SIZE = 50
    DEFAULT_SYSTEM_PROMPT = <<~PROMPT.squish
      <|eot_id|><|start_header_id|>user<|end_header_id|>
      You are a professional translator that translates content from the %{from} locale
      to the %{to} locale in an i18n locale array.

      The array has a structured format and contains multiple strings. Your task is to translate
      each of these strings and create a new array with the translated strings.

      HTML markups (enclosed in < and > characters) must not be changed under any circumstance.
      Variables (starting with %%{ and ending with }) must not be changed under any circumstance.

      Keep in mind the context of all the strings for a more accurate translation.
    PROMPT

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        from: from,
        to: to
      )
    end

    def options_for_html
      {}
    end

    def options_for_plain
      {}
    end

    def no_results_error_message
      I18n.t('i18n_tasks.watsonx_translate.errors.no_results')
    end

    private

    def translator
      @translator ||= WatsonxClient.new(project_id: project_id, key: api_key)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:watsonx_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.watsonx_translate.errors.no_api_key') if key.blank?

        key
      end
    end

    def project_id
      @project_id ||= begin
        key = @i18n_tasks.translation_config[:watsonx_project_id]
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.watsonx_translate.errors.no_project_id') if key.blank?

        project_id
      end
    end

    def model
      @model ||= @i18n_tasks.translation_config[:watsonx_model].presence || 'meta-llama/llama-3-1-70b-instruct'
    end

    def system_prompt
      @system_prompt ||= @i18n_tasks.translation_config[:watsonx_system_prompt].presence || DEFAULT_SYSTEM_PROMPT
    end

    def translate_values(list, from:, to:)
      results = []

      list.each_slice(BATCH_SIZE) do |batch|
        translations = translate(batch, from, to)

        results << JSON.parse(translations)
      end

      results.flatten
    end

    def translate(values, from, to)
      prompt = [
        format(system_prompt, from: from, to: to),
        "<|eot_id|><|start_header_id|>user<|end_header_id|>Translate this array: \n\n\n",
        "<|eot_id|><|start_header_id|>user<|end_header_id|>#{values.to_json}",
        "<|eot_id|><|start_header_id|>assistant<|end_header_id|>"
      ].concat

      response = translator.generate_text(
        {
          model: model,
          project_id: project_id,
          input: prompt
        }
      )

      response.dig('results', 0, 'generated_text')
    end
  end
end

class WatsonxClient
  WATSONX_BASE_URL = "https://us-south.ml.cloud.ibm.com/ml/"
  IBM_CLOUD_IAM_URL = "https://iam.cloud.ibm.com/identity/token"

  def initialize(project_id:, key:)
    @project_id = project_id

    @http = Faraday.new(url: WATSONX_BASE_URL) do |conn|
      conn.use Faraday::Response::RaiseError
      conn.request :json
      conn.response :json
      conn.options.timeout = 600
      conn.request :authorization, :Bearer, token(key)
    end
  end

  def generate_text(**opts)
    @http.post("v1/text/generation?version=2024-05-20", opts).body
  end

  private

  def token(key)
    Faraday.new(url: IBM_CLOUD_IAM_URL) do |conn|
      conn.use Faraday::Response::RaiseError
      conn.response :json
      conn.params = {
        grant_type: "urn:ibm:params:oauth:grant-type:apikey",
        apikey: key
      }
    end.post.body["access_token"]
  end
end
