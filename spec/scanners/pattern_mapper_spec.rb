# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/scanners/pattern_mapper'

RSpec.describe 'PatternMapper' do
  describe '#scan' do
    let(:mock_file_path) do
      'app/views/main/index.html'
    end
    let(:mock_file_contents) { <<-ERB }
      <%= title %>
      <%= Spree.t 'x' %>
      <%= Spree.t 'invalid.' %>
    ERB
    let(:expected_key_occurrences) do
      [make_key_occurrences('main.index.title', [{ path: mock_file_path, line_num: 1, line_pos: 7, pos: 6,
                                                   line: mock_file_contents.lines[0].chomp }]),
       make_key_occurrences('spree.x', [{ path: mock_file_path, line_num: 2, line_pos: 11, pos: 29,
                                          line: mock_file_contents.lines[1].chomp }])]
    end

    it 'maps patterns to keys' do
      mapper = I18n::Tasks::Scanners::PatternMapper.new(config: {
                                                          relative_roots: ['app/views'],
                                                          patterns: [[/<%\s*=\s*title/, '.title'],
                                                                     ['Spree\.t[( ]\s*%{key}', 'spree.%{key}']]
                                                        })
      expect(mapper).to receive(:traverse_files) { [mapper.send(:scan_file, mock_file_path)] }
      expect(mapper).to receive(:read_file).with(mock_file_path).and_return(mock_file_contents)
      expect(mapper.keys).to eq expected_key_occurrences
    end
  end
end
