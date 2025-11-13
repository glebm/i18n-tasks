# frozen_string_literal: true

require "cgi"
require "net/http"
require "uri"
require "json"
require "i18n/tasks/translators/base_translator"

# https://cloud.google.com/translate/docs/reference/rest/v2/translate

module I18n::Tasks::Translators
  class GoogleTranslator < BaseTranslator
    API_ENDPOINT = "https://translation.googleapis.com/language/translate/v2"
    MAX_TEXTS_PER_REQUEST = 128
    MAX_CHARS_PER_REQUEST = 30_000

    class Error < StandardError; end

    class RateLimitError < Error; end

    class QuotaExceededError < Error; end

    def initialize(*)
      super
    end

    protected

    def translate_values(list, **options)
      html = options[:html].present?
      result = restore_newlines(
        translate(
          texts: replace_newlines_with_placeholder(list),
          api_key: api_key,
          to: options[:to],
          from: options[:from],
          html:
        ),
        html:
      )

      @progress_bar.progress += result.size

      result
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        api_key: api_key,
        from: from,
        to: to
      )
    end

    def options_for_html
      {html: true}
    end

    def options_for_plain
      {format: "text"}
    end

    def no_results_error_message
      I18n.t("i18n_tasks.google_translate.errors.no_results")
    end

    private

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:google_translate_api_key]
        # fallback with deprecation warning
        if @i18n_tasks.translation_config[:api_key]
          warn_deprecated(
            "Please rename Google Translate API Key from `api_key` to `google_translate_api_key`."
          )
          key ||= translation_config[:api_key]
        end
        fail ::I18n::Tasks::CommandError, I18n.t("i18n_tasks.google_translate.errors.no_api_key") if key.blank?

        key
      end
    end

    def replace_newlines_with_placeholder(list)
      list.map do |value|
        value.gsub(/\n(\s*)/) do
          "<Z__#{::Regexp.last_match(1)&.length || 0}>"
        end
      end
    end

    def restore_newlines(translations, html:)
      restored = translations.map do |translation|
        translation.gsub(/<Z__(\d+)>/) do
          "\n#{" " * ::Regexp.last_match(1).to_i}"
        end
      end

      # Need to unescape if translating HTML content
      html ? restored.map { |t| CGI.unescapeHTML(t) } : restored
    end

    # @param texts [Array<String>] texts to translate
    # @param api_key [String] Google Translate API key (required)
    # @param to [String] target language code (required)
    # @param format [Symbol] :text or :html (required)
    # @param from [String] source language code
    # @return [Array<String>] translated texts
    def translate(texts:, api_key:, to:, html:, from: nil)
      texts = Array(texts)

      return [] if texts.empty?

      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?

      raise ArgumentError, "target language (:to) is required" if to.nil? || to.empty?

      # Split into batches if needed
      batches = batch_texts(texts)

      batches.flat_map do |batch|
        translate_batch(texts: batch, api_key:, to:, from:, html:)
      end
    end

    def batch_texts(texts)
      batches = []
      current_batch = []
      current_chars = 0

      texts.each do |text|
        text_length = text.to_s.length

        # If adding this text would exceed limits, start new batch
        if current_batch.size >= MAX_TEXTS_PER_REQUEST ||
            (current_chars + text_length > MAX_CHARS_PER_REQUEST && current_batch.any?)
          batches << current_batch
          current_batch = []
          current_chars = 0
        end

        current_batch << text
        current_chars += text_length
      end

      batches << current_batch if current_batch.any?
      batches
    end

    def translate_batch(texts:, api_key:, to:, from:, html:)
      uri = URI(API_ENDPOINT)
      # Provide API key via query string as expected by v2 API
      uri.query = URI.encode_www_form(key: api_key)

      body = {
        q: texts,
        target: to,
        format: html ? "html" : "text"
      }

      # Add source language if specified
      if from
        body[:source] = from
      end

      response = make_request(uri, body)
      parse_response(response, texts.size)
    end

    def make_request(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["User-Agent"] = "i18n-tasks/GoogleTranslateApi"
      request.body = JSON.generate(body)

      response = http.request(request)

      handle_error_response(response) unless response.is_a?(Net::HTTPSuccess)
      response
    end

    def parse_response(response, expected_count)
      data = JSON.parse(response.body)

      unless data["data"] && data["data"]["translations"]
        raise Error, "Unexpected API response format"
      end

      translations = data["data"]["translations"].map do |translation|
        translation["translatedText"]
      end

      if translations.size != expected_count
        raise Error, "Expected #{expected_count} translations, got #{translations.size}"
      end

      translations
    rescue JSON::ParserError => e
      raise Error, "Failed to parse API response: #{e.message}"
    end

    def handle_error_response(response)
      begin
        error_data = JSON.parse(response.body)
        error_message = error_data.dig("error", "message") || "Unknown error"
        error_code = error_data.dig("error", "code")
      rescue JSON::ParserError
        error_message = response.body
        error_code = response.code
      end

      status = response.code.to_i
      diagnostic = "(status=#{status}, code=#{error_code})"
      case status
      when 400
        raise Error, "Bad request #{diagnostic}: #{error_message}"
      when 401, 403
        raise Error, "Authentication/authorization failed #{diagnostic}: #{error_message}. " \
          "Ensure the Cloud Translation API v2 is enabled, billing is active, and the key is unrestricted for this API."
      when 429
        raise RateLimitError, "Rate limit exceeded #{diagnostic}: #{error_message}"
      when 503
        raise QuotaExceededError, "Quota exceeded #{diagnostic}: #{error_message}"
      else
        raise Error, "API error #{diagnostic}: #{error_message}"
      end
    end
  end
end
