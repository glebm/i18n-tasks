# frozen_string_literal: true

require "i18n/tasks/translators/base_translator"
require "i18n/clients/uvida_translation"

module I18n::Tasks::Translators
  class UvidaTranslator < BaseTranslator
    def initialize(*)
      super
    end

    protected

    def translate_values(list, **options)
      from = options[:from] || "en"
      to = options[:to]

      client = I18n::Clients::UvidaTranslation.new

      # The client handles its own error raising.
      translated_texts = client.translate(
        content: list,
        base_language: from,
        target_language: to,
        content_type: options[:html] ? "html" : "json"
      )

      @progress_bar.progress += translated_texts.size if @progress_bar
      translated_texts
    rescue I18n::Clients::UvidaTranslation::Error => e
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
