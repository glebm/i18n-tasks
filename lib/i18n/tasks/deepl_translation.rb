# frozen_string_literal: true

require 'deepl'
require 'i18n/tasks/html_keys'

module I18n::Tasks
  module DeeplTranslation
    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def deepl_translate_forest(forest, from)
      forest.inject empty_forest do |result, root|
        translated = deepl_translate_list(root.key_values(root: true), to: root.key, from: from)
        result.merge! Data::Tree::Siblings.from_flat_pairs(translated)
      end
    end

    # @param [Array<[String, Object]>] list of key-value pairs
    # @return [Array<[String, Object]>] translated list
    def deepl_translate_list(list, opts) # rubocop:disable Metrics/AbcSize
      return [] if list.empty?
      opts = opts.dup
      opts[:key] ||= translation_config[:deepl_api_key]
      deepl_validate_translate_api_key! opts[:key]
      key_pos = list.each_with_index.inject({}) { |idx, ((k, _v), i)| idx.update(k => i) }
      # copy reference keys as is, instead of translating
      reference_key_vals = list.select { |_k, v| v.is_a? Symbol } || []
      list -= reference_key_vals
      result = list.group_by { |k_v| html_key? k_v[0], opts[:from] }.map do |is_html, list_slice|
        deepl_fetch_translations list_slice, opts.merge(is_html ? { tag_handling: 'xml' } : { preserve_formatting: true })
      end.reduce(:+) || []
      result.concat(reference_key_vals)
      result.sort! { |a, b| key_pos[a[0]] <=> key_pos[b[0]] }
      result
    end

    # @param [Array<[String, Object]>] list of key-value pairs
    # @return [Array<[String, Object]>] translated list
    def deepl_fetch_translations(list, opts)
      options = {
        ignore_tags: %w[i18n]
      }.merge(opts)
      deepl_from_values(list, DeepL.translate(deepl_to_values(list), opts[:from], opts[:to], options)).tap do |result|
        fail CommandError, I18n.t('i18n_tasks.deepl_translate.errors.no_results') if result.blank?
      end
    end

    private

    def deepl_validate_translate_api_key!(key)
      fail CommandError, I18n.t('i18n_tasks.deepl_translate.errors.no_api_key') if key.blank?
      DeepL.configure do |config|
        config.auth_key = key
      end
    end

    # @param [Array<[String, Object]>] list of key-value pairs
    # @return [Array<String>] values for translation extracted from list
    def deepl_to_values(list)
      list.map { |l| deepl_dump_value l[1] }.flatten.compact
    end

    # @param [Array<[String, Object]>] list
    # @param [Array<String>] translated_values
    # @return [Array<[String, Object]>] translated key-value pairs
    def deepl_from_values(list, translated_values)
      keys                = list.map(&:first)
      untranslated_values = list.map(&:last)
      translated_values   = Array(translated_values).map(&:text)
      keys.zip deepl_parse_value(untranslated_values, translated_values.to_enum)
    end

    # Prepare value for translation.
    # @return [String, Array<String, nil>, nil] value for DeepL Translate or nil for non-string values
    def deepl_dump_value(value)
      case value
      when Array
        # dump recursively
        value.map { |v| deepl_dump_value v }
      when String
        deepl_replace_interpolations value
      end
    end

    # Parse translated value from the each_translated enumerator
    # @param [Object] untranslated
    # @param [Enumerator] each_translated
    # @return [Object] final translated value
    def deepl_parse_value(untranslated, each_translated)
      case untranslated
      when Array
        # implode array
        untranslated.map { |from| deepl_parse_value(from, each_translated) }
      when String
        deepl_restore_interpolations untranslated, each_translated.next
      else
        untranslated
      end
    end

    INTERPOLATION_KEY_RE = /(%\{[^}]+})/

    # @param [String] value
    # @return [String] 'hello, %{name}' => 'hello, <i18n>%{name}</i18n>'
    def deepl_replace_interpolations(value)
      value.gsub(INTERPOLATION_KEY_RE, '<i18n>\1</i18n>')
    end

    # @param [String] untranslated
    # @param [String] translated
    # @return [String] 'hello, <i18n>%{name}</i18n>' => 'hello, %{name}'
    def deepl_restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE
      translated.gsub(%r{<\/?i18n>}, '')
    rescue StandardError => e
      raise CommandError.new(e, <<-TEXT.strip)
Error when restoring interpolations:
  original: "#{untranslated}"
  response: "#{translated}"
  error: #{e.message} (#{e.class.name})
      TEXT
    end
  end
end
