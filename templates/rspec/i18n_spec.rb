# frozen_string_literal: true

require 'i18n/tasks'

RSpec.describe I18n do
  let(:i18n) { I18n::Tasks::BaseTask.new }
  let(:missing_keys) { i18n.missing_keys }
  let(:unused_keys) { i18n.unused_keys }
  let(:inconsistent_interpolations) { i18n.inconsistent_interpolations }
  let(:non_normalized) { i18n.non_normalized_paths }
  let(:normalization_error_message) do
    "The following files need to be normalized:\n" \
    "#{non_normalized.map { |path| "  #{path}" }.join("\n")}\n" \
    "Please run `i18n-tasks normalize' to fix"
  end
  let(:interpolation_error_message) do
    "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\n" \
    "Run `i18n-tasks check-consistent-interpolations' to show them"
  end

  it 'does not have missing keys' do
    expect(missing_keys).to be_empty,
                            "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
  end

  it 'does not have unused keys' do
    expect(unused_keys).to be_empty,
                           "#{unused_keys.leaves.count} unused i18n keys, run `i18n-tasks unused' to show them"
  end

  it 'files are normalized' do
    expect(non_normalized).to be_empty, normalization_error_message
  end

  it 'does not have inconsistent interpolations' do
    expect(inconsistent_interpolations).to be_empty, interpolation_error_message
  end
end
