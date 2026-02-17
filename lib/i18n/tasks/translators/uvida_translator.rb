# frozen_string_literal: true

require "i18n/tasks/translators/base_translator"

module I18n::Tasks::Translators
  class UvidaTranslator < BaseTranslator
    def initialize(*)
      super
    end

    protected

    def translate_values(list, **options)
      from = options[:from] || "en"
      to = options[:to]

      client = Clients::Translation.new

      # The client handles its own error raising, but we might want to wrap it
      # to match i18n-tasks expectations if needed.
      response = client.translate(
        content: list,
        base_language: from,
        target_language: to,
        content_type: options[:html] ? "html" : "json"
      )

      # Check if response is an error (Clients::Translation returns response if not 2xx-3xx,
      # but it also raises error in some cases. Looking at translation.rb:
      # return response if !response.code.to_i.between?(200, 300)
      # return body if response.code.to_i.in?(200...300)
      # raise ::Clients::Translation::Error.new(...)

      if response.is_a?(Net::HTTPResponse)
        raise "Uvida Translation Error: #{response.code} #{response.body}"
      end

      # Assuming response is the array of translated strings
      translated_texts = response

      @progress_bar.progress += translated_texts.size if @progress_bar
      translated_texts
    rescue Clients::Translation::Error => e
      raise "Uvida Translation Error: #{e.message} (Status: #{e.status})"
    rescue StandardError => e
      raise "Uvida Translation Error: #{e.message}"
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(from: from, to: to)
    end

    def options_for_html
      { html: true }
    end

    def options_for_plain
      { html: false }
    end

    def no_results_error_message
      "Uvida translator returned no results."
    end
  end
end
