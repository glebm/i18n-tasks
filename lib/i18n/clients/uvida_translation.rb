# frozen_string_literal: true

module I18n
  module Clients
    class UvidaTranslation
      class Error < StandardError
        attr_reader :status

        def initialize(error, status: 500)
          @status = status
          super(error)
        end
      end

      def initialize(attributes = {})
        @base_url ||= ENV.fetch("UVIDA_TRANSLATION_SERVICE_URL")
        @token ||= ENV.fetch("UVIDA_TRANSLATION_SERVICE_TOKEN")
      end

      def translate(content:, base_language:, target_language:, content_type: "json")
        url = URI("#{@base_url}/translate-content")
        url.query = URI.encode_www_form({
                                          target_language: target_language,
                                          base_language: base_language,
                                          content_type: content_type
                                        })

        @request = Net::HTTP::Post.new(url, header)
        @request.body = content.to_json

        response = send_request(url)
        code = response.code.to_i

        unless (200...300).cover?(code)
          body = JSON.parse(response.body) rescue response.body
          raise Error.new("Translation failed: #{body}", status: code)
        end

        JSON.parse(response.body)
      end

      private

      def send_request(url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        http.request(@request)
      end

      def header
        {
          "Accept" => "application/json",
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
      end
    end
  end
end
