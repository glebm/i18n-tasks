# coding: utf-8

module I18n
  module Tasks
    module UnusedKeys
      # @return [Array<[String, String]>] all the unused translations as an array of [key, value] pairs
      def unused_keys
        traverse_map_if data[base_locale] do |key, value|
          next if pattern_key?(key) || ignore_key?(key, :unused)
          key = depluralize_key(key)
          [key, value] unless used_key?(key)
        end.uniq
      end
    end
  end
end