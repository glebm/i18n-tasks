# frozen_string_literal: true

module KeysAndOccurrences
  # rubocop:disable Metrics/ParameterLists
  def make_occurrence(
    path: "",
    line: "",
    pos: 1,
    line_pos: 1,
    line_num: 1,
    raw_key: nil,
    candidate_keys: nil
  )
    ::I18n::Tasks::Scanners::Results::Occurrence.new(
      path: path,
      line: line,
      pos: pos,
      line_pos: line_pos,
      line_num: line_num,
      raw_key: raw_key,
      candidate_keys: candidate_keys
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def make_occurrences(occurrences)
    occurrences.map { |attr| make_occurrence(**attr) }
  end

  def make_key_occurrences(key, occurrences)
    ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(
      key: key,
      occurrences: make_occurrences(occurrences)
    )
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
    occurrence.dup.tap do |o|
      o.instance_variable_set(:@pos, o.pos + o.line_num - 1)
    end
  end

  def leaves_to_hash(leaves)
    leaves.to_h { |leaf| [leaf.full_key(root: false), leaf] }
  end

  def expected_occurrences(leaves, expected)
    expect(leaves.keys).to match_array(expected.keys)
    leaves.each do |key, leaf|
      expected_data = expected[key]
      occurrences = leaf.data[:occurrences]
      expect(occurrences).not_to be_nil
      expect(occurrences.size).to(eq(expected_data.size))

      occurrences_to_compare =
        occurrences.map { |occ| {path: occ.path, line_num: occ.line_num} }
      expect(occurrences_to_compare).to(match_array(expected_data))
    end
  end
end
