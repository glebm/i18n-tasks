# frozen_string_literal: true

require "json"
require "open3"
require "i18n/tasks/translators/base_translator"
require "active_support/core_ext/string/filters"

module I18n::Tasks::Translators
  class ClaudeCodeTranslator < BaseTranslator
    include ::I18n::Tasks::Data::LanguageNames

    DEFAULT_MODEL = "claude-sonnet-5-5"
    BATCH_SIZE = 200
    DEFAULT_SYSTEM_PROMPT = <<~PROMPT.squish
      You are a professional translator that translates content from the %{from} locale
      to the %{to} locale in an i18n locale array.

      The array has a structured format and contains multiple strings. Your task is to translate
      each of these strings and return the translated strings in the same order.

      HTML markups (enclosed in < and > characters) must not be changed under any circumstance.
      Placeholders of the form X__0, X__1, etc. must not be changed under any circumstance.

      Keep in mind the context of all the strings for a more accurate translation.
    PROMPT
    OUTPUT_SCHEMA = {
      type: "object",
      properties: {translations: {type: "array", items: {type: "string"}}},
      required: ["translations"],
      additionalProperties: false
    }.freeze

    def options_for_translate_values(from:, to:, **options)
      options.merge(from: from, to: to)
    end

    def options_for_html
      {}
    end

    def options_for_plain
      {}
    end

    def translation_batches(list, _options)
      list.each_slice(BATCH_SIZE).to_a
    end

    def no_results_error_message
      I18n.t("i18n_tasks.claude_code_translate.errors.no_results")
    end

    protected

    def request_translations(system_prompt, values)
      stdout, stderr, status = Open3.capture3(*cli_arguments(system_prompt), stdin_data: user_message(values))
      result = parse_result(stdout, stderr)
      if !status.success? || result["is_error"]
        fail "Claude Code failed: #{result["result"].presence || stderr.strip}"
      end

      result.dig("structured_output", "translations")
    rescue Errno::ENOENT
      raise ::I18n::Tasks::CommandError, I18n.t("i18n_tasks.claude_code_translate.errors.not_installed")
    end

    private

    def translate_values(list, from:, to:)
      return [] if list.empty?

      result = request_translations(system_prompt(from, to), list)
      @progress_bar.progress += result.size
      result
    end

    def cli_arguments(system_prompt)
      [
        executable, "-p",
        "--model", model,
        *(effort ? ["--effort", effort] : []),
        "--system-prompt", system_prompt,
        "--json-schema", OUTPUT_SCHEMA.to_json,
        "--output-format", "json",
        "--tools", "",
        "--setting-sources", "",
        "--strict-mcp-config",
        "--disable-slash-commands",
        "--no-session-persistence"
      ]
    end

    def parse_result(stdout, stderr)
      JSON.parse(stdout)
    rescue JSON::ParserError
      fail "Claude Code returned unexpected output: #{stderr.strip.presence || stdout.strip}"
    end

    def user_message(values)
      "Translate this array:\n\n#{values.to_json}"
    end

    def system_prompt(from, to)
      prompt = locale_prompts[to].presence || config[:claude_system_prompt].presence || DEFAULT_SYSTEM_PROMPT
      format(prompt, from: language_name(from), to: language_name(to))
    end

    def locale_prompts
      config[:claude_locale_prompts] || {}
    end

    def model
      config[:claude_model].presence || DEFAULT_MODEL
    end

    def effort
      config[:claude_effort].presence
    end

    def executable
      config[:claude_code_executable].presence || "claude"
    end

    def config
      @i18n_tasks.translation_config
    end
  end
end
