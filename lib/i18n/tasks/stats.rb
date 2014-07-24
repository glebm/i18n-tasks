module I18n::Tasks
  module Stats
    def forest_stats(forest)
      key_count    = forest.leaves.count
      locale_count = forest.count
      if key_count.zero?
        {key_count: 0}
      else
        {
            locales:          forest.map(&:key).join(', '),
            key_count:        key_count,
            locale_count:     locale_count,
            per_locale_avg:   forest.inject(0) { |sum, f| sum + f.leaves.count } / locale_count,
            key_segments_avg: '%.1f' % (forest.leaves.inject(0) { |sum, node| sum + node.walk_to_root.count - 1 } / key_count),
            value_chars_avg:  forest.leaves.inject(0) { |sum, node| sum + node.value.length } / key_count
        }
      end
    end
  end
end
