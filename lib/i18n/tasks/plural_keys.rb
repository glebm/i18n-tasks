# frozen_string_literal: true

require "set"
module I18n::Tasks::PluralKeys
  # Ref: http://cldr.unicode.org/index/cldr-spec/plural-rules
  CLDR_CATEGORY_KEYS = %w[zero one two few many other].freeze
  PLURAL_KEY_SUFFIXES = Set.new CLDR_CATEGORY_KEYS
  PLURAL_KEY_RE = /\.(?:#{CLDR_CATEGORY_KEYS * "|"})$/
  # Ref: https://unicode-org.github.io/cldr/ldml/tr35-numbers.html#Explicit_0_1_rules
  EXPLICIT_0_1 = %w[0 1].freeze

  def collapse_plural_nodes!(tree)
    tree.leaves.map(&:parent).compact.uniq.each do |node|
      children = node.children
      next unless plural_forms?(children)

      node.value = children.to_hash
      node.children = nil
      node.data.merge! children.first.data
    end
    tree
  end

  # @param [String] key i18n key
  # @param [String] locale to pull key data from
  # @return [String] the base form if the key is a specific plural form (e.g. apple for apple.many), the key otherwise.
  def depluralize_key(key, locale = base_locale)
    return key if key !~ PLURAL_KEY_RE

    key_name = last_key_part(key)
    parent_key = key[0..- (key_name.length + 2)]
    nodes = tree("#{locale}.#{parent_key}").presence || (locale != base_locale && tree("#{base_locale}.#{parent_key}"))
    if nodes && plural_forms?(nodes)
      parent_key
    else
      key
    end
  end

  # @param [::I18n::Tasks::Data::Tree::Traversal] tree
  # @yieldparam node [::I18n::Tasks::Data::Tree::Node] plural node
  def plural_nodes(tree)
    return to_enum(:plural_nodes, tree) unless block_given?

    visited = Set.new
    tree.leaves do |node|
      parent = node.parent
      next if !parent || visited.include?(parent)

      yield parent if plural_forms?(parent.children)
      visited.add(parent)
    end
    self
  end

  def plural_forms?(s)
    s.present? && s.all? { |node| node.leaf? && plural_suffix?(node.key) }
  end

  def plural_suffix?(key)
    PLURAL_KEY_SUFFIXES.include?(key) || EXPLICIT_0_1.include?(key)
  end

  # @param [String] locale
  # @return [Hash, nil] the rails-i18n plural configuration of the locale (`:keys` and `:rule`), nil if it has none.
  def rails_i18n_plural_config(locale)
    @rails_i18n_plural_configs ||= {}
    return @rails_i18n_plural_configs[locale] if @rails_i18n_plural_configs.key?(locale)

    @rails_i18n_plural_configs[locale] = begin
      configuration = load_rails_i18n_pluralization!(locale)
      configuration = configuration[locale.to_sym] || configuration[alternate_locale_from(locale).to_sym]
      configuration&.dig(:i18n, :plural)
    rescue SystemCallError, IOError
      nil
    end
  end

  # Loads rails-i18n pluralization config for the given locale.
  def load_rails_i18n_pluralization!(locale)
    path = File.join(Gem::Specification.find_by_name("rails-i18n").gem_dir, "rails", "pluralization", "#{locale}.rb")
    eval(File.read(path), binding, path) # rubocop:disable Security/Eval
  end

  # Counts from 0 up to this cover every plural rule in rails-i18n, as they look at `n % 100` at most.
  PLURAL_RULE_COUNTS = (0..1000)

  # @param [String] locale
  # @param [Array<String>] form_keys the plural forms of a group in the locale
  # @return [Hash{String => Integer}, nil] how many counts in PLURAL_RULE_COUNTS select each form,
  #   with the locale's rails-i18n rule, nil if the locale has no rule.
  def plural_form_counts(locale, form_keys)
    rule = rails_i18n_plural_config(locale)&.dig(:rule)
    return unless rule.respond_to?(:call)

    @plural_form_counts ||= {}
    @plural_form_counts[[locale, form_keys.sort]] ||=
      PLURAL_RULE_COUNTS.map { |count| plural_form_for_count(rule, form_keys, count) }.tally
  end

  private

  # The form I18n::Backend::Pluralization picks for the count.
  def plural_form_for_count(rule, form_keys, count)
    return "zero" if count.zero? && form_keys.include?("zero")
    return count.to_s if count <= 1 && form_keys.include?(count.to_s)

    category = rule.call(count).to_s
    form_keys.include?(category) ? category : "other"
  end

  def alternate_locale_from(locale)
    re = /(\w{2})-*(\w{2,3})*/
    match = locale.match(re)
    language_code = match[1]
    country_code = match[2]
    "#{language_code}-#{country_code&.upcase}"
  end
end
