# frozen_string_literal: true
require 'set'
module I18n::Tasks::PluralKeys
  PLURAL_KEY_SUFFIXES = Set.new %w(zero one two few many other)
  PLURAL_KEY_RE = /\.(?:#{PLURAL_KEY_SUFFIXES.to_a * '|'})$/

  def collapse_plural_nodes!(tree)
    tree.leaves.map(&:parent).compact.uniq.each do |node|
      children = node.children
      next unless plural_forms?(children)
      node.value    = children.to_hash
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

  def plural_forms?(s)
    s.present? && s.all? { |node| node.leaf? && plural_suffix?(node.key) }
  end

  def plural_suffix?(key)
    PLURAL_KEY_SUFFIXES.include?(key)
  end
end
