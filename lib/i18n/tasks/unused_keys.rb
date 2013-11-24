# coding: utf-8

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_keys(locale = base_locale)
        traverse_map_if data[locale] do |key, value|
          next if pattern_key?(key) || ignore_key?(key, :unused)
          key = depluralize_key(locale, key)
          [key, value] unless used_key?(key)
        end.uniq
      end
    end
  end
end