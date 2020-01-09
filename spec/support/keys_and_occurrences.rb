# frozen_string_literal: true

module KeysAndOccurrences
  # rubocop:disable Metrics/ParameterLists
  def make_occurrence(path: '', line: '', pos: 1, line_pos: 1, line_num: 1, raw_key: nil)
    ::I18n::Tasks::Scanners::Results::Occurrence.new(
      path: path, line: line, pos: pos, line_pos: line_pos, line_num: line_num, raw_key: raw_key
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def make_occurrences(occurrences)
    occurrences.map { |attr| make_occurrence(**attr) }
  end

  def make_key_occurrences(key, occurrences)
    ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(key: key, occurrences: make_occurrences(occurrences))
  end

  # adjust position to account for \r on Windows
  def adjust_occurrences(data)
    if Gem.win_platform?
      data = data.dup
      data[:occurrences].map! { |occ| adjust_occurrence occ }
    end
    data
  end

  # adjust position to account for \r on Windows
  def adjust_occurrence(occurrence)
    occurrence.dup.tap { |o| o.instance_variable_set(:@pos, o.pos + o.line_num - 1) }
  end
end
