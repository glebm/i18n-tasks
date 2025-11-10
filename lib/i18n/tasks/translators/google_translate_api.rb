# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module I18n::Tasks::Translators
  # https://cloud.google.com/translate/docs/reference/rest/v2/translate
  class GoogleTranslateApi
    class Error < StandardError; end
    class RateLimitError < Error; end
    class QuotaExceededError < Error; end

    API_ENDPOINT = "https://translation.googleapis.com/language/translate/v2"
    MAX_TEXTS_PER_REQUEST = 128
    MAX_CHARS_PER_REQUEST = 30_000

    class << self
      # Translate an array of texts
      # @param texts [Array<String>] texts to translate
      # @param options [Hash] translation options
      # @option options [String] :api_key Google Translate API key (required)
      # @option options [String] :from source language code
      # @option options [String] :to target language code (required)
      # @option options [Symbol] :format :text or :html
      # @return [Array<String>] translated texts
      def translate(texts, options = {})
        texts = Array(texts)

        return [] if texts.empty?

        api_key = options[:api_key] || options["api_key"]
        raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?

        target = options[:to] || options["to"]
        raise ArgumentError, "target language (:to) is required" if target.nil? || target.empty?

        # Split into batches if needed
        batches = batch_texts(texts)

        batches.flat_map do |batch|
          translate_batch(batch, api_key, options)
        end
      end

      private

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

      def translate_batch(texts, api_key, options)
        uri = URI(API_ENDPOINT)
        # Provide API key via query string as expected by v2 API
        uri.query = URI.encode_www_form(key: api_key)

        body = {
          q: texts,
          target: options[:to] || options["to"],
          format: format_param(options[:format] || options["format"])
        }

        # Add source language if specified
        if options[:from] || options["from"]
          body[:source] = options[:from] || options["from"]
        end

        response = make_request(uri, body)
        parse_response(response, texts.size)
      end

      def format_param(format)
        case format&.to_sym
        when :html then "html"
        when :text then "text"
        else "text"
        end
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
end
