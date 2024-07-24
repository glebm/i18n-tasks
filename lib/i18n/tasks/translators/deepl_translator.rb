# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'

module I18n::Tasks::Translators
  class DeeplTranslator < BaseTranslator # rubocop:disable Metrics/ClassLength
    # max allowed texts per request
    BATCH_SIZE = 50
    # those languages must be specified with their sub-kind e.g en-us
    SPECIFIC_TARGETS = %w[en pt].freeze

    def initialize(*)
      begin
        require 'deepl'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'deepl-rb' to your Gemfile to use this command"
      end
      super
      configure_api_key!
    end

    protected

    def translate_values(list, from:, to:, **options)
      results = []

      if (glossary = glossary_for(from, to))
        options.merge!({ glossary_id: glossary.id })
      end

      list.each_slice(BATCH_SIZE) do |parts|
        res = DeepL.translate(
          parts,
          to_deepl_source_locale(from),
          to_deepl_target_locale(to),
          options_with_glossary(options, from, to)
        )
        if res.is_a?(DeepL::Resources::Text)
          results << res.text
        else
          results += res.map(&:text)
        end
      end
      results
    end

    def options_for_translate_values(**options)
      extra_options = @i18n_tasks.translation_config[:deepl_options]&.symbolize_keys || {}

      extra_options.merge({ ignore_tags: %w[i18n] }).merge(options)
    end

    def options_for_html
      { tag_handling: 'xml' }
    end

    def options_for_plain
      { preserve_formatting: true, tag_handling: 'xml', html_escape: true }
    end

    # @param [String] value
    # @return [String] 'hello, %{name}' => 'hello, <i18n>%{name}</i18n>'
    def original_replace_interpolations(value)
      value.gsub(INTERPOLATION_KEY_RE, '<i18n>\0</i18n>')
    end

    # @param [String] untranslated
    # @param [String] translated
    # @return [String] 'hello, <i18n>%{name}</i18n>' => 'hello, %{name}'
    def original_restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE

      translated.gsub(%r{</?i18n>}, '')
    rescue StandardError => e
      raise_interpolation_error(untranslated, translated, e)
    end

    # deepl does a better job with interpolations when it doesn't have to deal
    # with <br> tags, so we replace all of them with meaningless asterisk chains
    BR_REGEXP = %r{(<br\s*/?>\s*)+}i.freeze
    BR_SINGLE_MARKER = ' *** '
    BR_DOUBLE_MARKER = ' ***** '

    # letting deepl 'read' the interpolations gives better translations (and
    # solves the problem of interpolations getting pushed all the way to the
    # front of the sentence), however, deepl will also try to translate
    # the interpolations and that gets messy.
    # we use nonsense three-letter acronyms so deepl will 'read' them and leave
    # them alone (the letter X also works very well, except in sentences with
    # several consecutive interpolations because that reads X X X and deepl
    # doesn't handle that well)
    # deepl also needs to know if an interpolation will be a word or a number,
    # for romance languages it matters. a little Spanish lesson to illustrate:
    # "%{foo} betalingen" translates either to "facturas %{foo}"
    # (openstaande betalingen -> facturas pendientes) or to "%{foo} facturas"
    # (5 betalingen -> 5 facturas)
    # for interpolation keys that are usually numeric, we pick a number
    # instead of the three-letter acronym (more consistency in how we name
    # interpolation keys would help)
    LETTER_SUBS = %w[RYX QFN VLB XOG DWP ZMQ JZQ WVS LRX HPM].freeze
    NUM_SUBS = %w[17 19 23 29 31 37 41 43 47 53].freeze

    def sub_for_handle(handle, index)
      case handle.gsub(/[^a-z]/, '')
      when 'count', 'minutes', 'hours'
        NUM_SUBS[index % NUM_SUBS.size]
      else
        LETTER_SUBS[index % LETTER_SUBS.size]
      end
    end

    # BEX version of replace_interpolation
    def replace_interpolations(value)
      index = 0
      value.gsub(INTERPOLATION_KEY_RE) do |handle|
        sub = sub_for_handle(handle, index)
        index += 1
        "<var handle=\"#{handle}\" sub=\"#{sub}\">#{sub}</var>"
      end.gsub(BR_REGEXP) do |br|
        if br.downcase.count('b') == 2
          # never more than two <br> in a row, it gets messy
          BR_DOUBLE_MARKER
        else
          BR_SINGLE_MARKER
        end
      end
    end

    # reversing our substitutions should be straight-forward, but it's not
    # because deepl gets creative. cases are explained inline.
    def restore_interpolations(untranslated, translated)
      translated.gsub(%r{(.?)<var handle="([^"]*)" sub="([^"]*)">([^<]*)</var>}) do
        char = ::Regexp.last_match(1)
        handle = ::Regexp.last_match(2)
        sub = ::Regexp.last_match(3)
        body = ::Regexp.last_match(4)
        if body == sub
          # deepl kept the 'sub' text inside the <var> tag and nothing else, clean.
          "#{char}#{handle}"
        elsif body.index(sub)
          # deepl took some letters from outside the <var> tag and placed them
          # inside the <var> e.g. task <var>"RYX</var>"
          before, after = body.split(sub, 2)
          "#{before}#{handle}#{after}"
        elsif "#{char}#{body}".downcase == sub.downcase
          # deepl took the first letter from inside the <var> tag and placed it
          # immediately before the <var> tag e.g. R<var>yx</var>
          handle
        else
          # instead of trying to look normal the fallback prints something
          # obviously wrong hoping to get some attention and a manual fix
          "!!!!!#{sub.inspect} (#{char.inspect} #{body.inspect})!!!!!"
        end
      end.gsub(BR_DOUBLE_MARKER, '<br /><br />').gsub(BR_SINGLE_MARKER, '<br />')
    rescue StandardError => e
      raise_interpolation_error(untranslated, translated, e)
    end

    def no_results_error_message
      I18n.t('i18n_tasks.deepl_translate.errors.no_results')
    end

    private

    # Convert 'es-ES' to 'ES', en-us to EN
    def to_deepl_source_locale(locale)
      locale.to_s.split('-', 2).first.upcase
    end

    # Convert 'es-ES' to 'ES' but warn about locales requiring a specific variant
    def to_deepl_target_locale(locale)
      loc, sub = locale.to_s.split('-')
      if SPECIFIC_TARGETS.include?(loc)
        # Must see how the deepl api evolves, so this could be an error in the future
        warn_deprecated I18n.t('i18n_tasks.deepl_translate.errors.specific_target_missing') unless sub
        locale.to_s.upcase
      else
        loc.upcase
      end
    end

    # Find the largest glossary given a language pair
    def glossary_for(source, target)
      DeepL.glossaries.list.select do |glossary|
        glossary.source_lang == source && glossary.target_lang == target
      end.max_by(&:entry_count)
    end

    def configure_api_key!
      api_key = @i18n_tasks.translation_config[:deepl_api_key]
      host = @i18n_tasks.translation_config[:deepl_host]
      version = @i18n_tasks.translation_config[:deepl_version]
      fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.deepl_translate.errors.no_api_key') if api_key.blank?

      DeepL.configure do |config|
        config.auth_key = api_key
        config.host = host unless host.blank?
        config.version = version unless version.blank?
      end
    end

    def options_with_glossary(options, from, to)
      glossary = find_glossary(from, to)
      glossary ? { glossary_id: glossary.id }.merge(options) : options
    end

    def all_ready_glossaries
      @all_ready_glossaries ||= DeepL.glossaries.list
    end

    def find_glossary(from, to)
      config_glossary_ids = @i18n_tasks.translation_config[:deepl_glossary_ids]
      return unless config_glossary_ids

      all_ready_glossaries.find do |glossary|
        glossary.ready \
          && glossary.source_lang == from \
          && glossary.target_lang == to \
          && config_glossary_ids.include?(glossary.id)
      end
    end
  end
end
