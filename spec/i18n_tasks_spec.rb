# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'open3'

# Integration tests
RSpec.describe 'i18n-tasks' do
  delegate :run_cmd, :run_cmd_capture_stdout_and_result, :run_cmd_capture_stderr, :i18n_task, :in_test_app_dir,
           to: :TestCodebase

  describe 'bin/i18n-tasks' do
    it 'shows help when invoked with no arguments, shows version on --version' do
      skip "Doesn't work jruby and rbx due to Open3 issues" if RUBY_ENGINE == 'jruby' || RUBY_ENGINE == 'rbx'
      # These bin/i18n-tasks tests are executed in parallel for performance
      env = { 'I18N_TASKS_BIN_SIMPLECOV_COVERAGE' => '1' }
      run = ->(*args) { Bundler.with_original_env { Open3.capture3(env, *args) } }
      in_test_app_dir do
        clean_unrelated_warnings = lambda do |s|
          s.sub(%r{^warning: parser/cur.*?https://github.com/whitequark/parser#compatibility-with-ruby-mri\.\n}m, '')
           .gsub(/^.*warning: constant ::(?:Fixnum|Bignum) is deprecated\n/, '')
        end
        clean_coverage_logging = lambda { |s|
          s.sub(/(?:\n^|\A)(?:Coverage = |.*Reporting coverage|JSON Coverage report).*(?:$\n|\z)/i, '')
        }
        [
          proc do
            out, err, status = run.call('bundle exec ../../bin/i18n-tasks')
            out = clean_coverage_logging[out]
            err = clean_unrelated_warnings[clean_coverage_logging[err]]
            expect(status).to be_success
            expect(out).to be_empty
            expect(err.lines.first.chomp).to eq('Usage: i18n-tasks [command] [options]')
            expect(err).to a_string_including('Available commands', 'add-missing')
            # a task from a plugin
            expect(err).to a_string_including('greet')
          end,
          proc do
            out, err, status = run.call('bundle exec ../../bin/i18n-tasks --version')
            out = clean_coverage_logging[out]
            err = clean_unrelated_warnings[clean_coverage_logging[err]]
            expect(status).to be_success
            expect(err).to be_empty
            expect(out.chomp).to eq I18n::Tasks::VERSION
          end
        ].map { |test| Thread.start(&test) }.each(&:join)
      end
    end
  end

  # Tests execute i18n-tasks using I18n::Tasks::CLI directly, via #run_cmd(task, *arguments).
  # This avoid launching a process for each command.

  describe 'health' do
    it 'outputs stats' do
      t     = i18n_task
      out   = run_cmd_capture_stderr('health')
      in_test_app_dir { t.forest_stats(t.data_forest(t.locales)) }.each_value do |v|
        expect(out).to include(v.to_s)
      end
    end
  end

  describe 'missing' do
    let :expected_missing_keys_in_source do
      %w[
        used_but_missing.key
        relative.index.missing
        hash.pattern_missing.a
        hash.pattern_missing.b
        missing_symbol_key
        missing_symbol.key_two
        missing_symbol.key_three
        missing-key-with-a-dash.key
        missing_key_ending_in_colon.key:
        missing-key-question?.key
        fn_comment
        events.show.success
        index.my_custom_scanner.title
        magic_comment
        default_arg
        .not_relative
        scope.subscope.a.b
        scope.key_in_erb
        scope.relative.index.title
        reference-missing-target.a
        nested.parent.rb
        nested.child.rb
      ] + ['⮕ missing_target']
    end
    let :expected_missing_keys_diff do
      %w[
        es.missing_in_es.a
        en.present_in_es_but_not_en.a
        es.missing_in_es_plural_1.a
        es.missing_in_es_plural_2.a
        en.only_in_es
        es.external.missing_in_es
      ]
    end
    it 'detects missing' do
      es_keys = expected_missing_keys_diff.grep(/^es\./) +
                (expected_missing_keys_in_source.map { |k| k[0] == '⮕' ? k : "es.#{k}" })
      out, result = run_cmd_capture_stdout_and_result 'missing'
      expect(result).to eq :exit1
      expect(out).to be_i18n_keys(expected_missing_keys_diff +
                                      (expected_missing_keys_in_source.map { |k| k[0] == '⮕' ? k : "all.#{k}" }))
      expect(run_cmd('missing', '-les')).to be_i18n_keys es_keys
      expect(run_cmd('missing', 'es')).to be_i18n_keys es_keys
    end
  end

  describe 'eq_base' do
    it 'detects eq-base' do
      expect(run_cmd('eq-base')).to be_i18n_keys %w[es.same_in_es.a]
    end
  end

  let(:expected_unused_keys) do
    %w[unused.a unused.file unused.not-in-write unused.numeric unused.plural reference-unused
       reference-unused-target].map do |k|
      %w[en es].map { |l| "#{l}.#{k}" }
    end.reduce(:+)
  end

  let(:expected_unused_keys_strict) do
    expected_unused_keys + %w[hash.pattern.a hash.pattern2.a hash.pattern3.x.y.z].map do |k|
      %w[en es].map { |l| "#{l}.#{k}" }
    end.reduce(:+)
  end

  describe 'unused' do
    it 'detects unused (--no-strict)' do
      out, result = run_cmd_capture_stdout_and_result('unused', '--no-strict')
      expect(result).to eq :exit1
      expect(out).to be_i18n_keys expected_unused_keys
    end

    it 'detects unused (--strict)' do
      expect(run_cmd('unused', '--strict')).to be_i18n_keys expected_unused_keys_strict
    end
  end

  describe 'remove_unused' do
    it 'removes unused' do
      in_test_app_dir do
        t      = i18n_task
        unused = expected_unused_keys.map { |k| ::I18n::Tasks::SplitKey.split_key(k, 2)[1] }
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be true
          expect(t.key_value?(key, :es)).to be true
        end
        ENV['CONFIRM'] = '1'
        run_cmd 'remove-unused'
        t.data.reload
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be false
          expect(t.key_value?(key, :es)).to be false
        end
      end
    end

    it 'sorts the keys' do
      in_test_app_dir do
        ENV['CONFIRM'] = '1'
        run_cmd 'remove-unused'
        en_yml_data = i18n_task.data.reload['en'].select_keys do |_k, node|
          node.data[:path] == 'config/locales/en.yml'
        end
        expect(en_yml_data).to be_present
        en_yml_data.nodes do |nodes|
          next unless nodes.children

          keys = nodes.children.map(&:key)
          expect(keys).to eq keys.sort
        end
      end
    end

    it 'removes unused (--keep-order)' do
      in_test_app_dir do
        t      = i18n_task
        unused = expected_unused_keys.map { |k| ::I18n::Tasks::SplitKey.split_key(k, 2)[1] }
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be true
          expect(t.key_value?(key, :es)).to be true
        end

        ENV['CONFIRM'] = '1'
        run_cmd 'remove-unused', '--keep-order'
        t.data.reload
        unused.each do |key|
          expect(t.key_value?(key, :en)).to be false
          expect(t.key_value?(key, :es)).to be false
        end
      end
    end

    it 'does not sort the keys (--keep-order)' do
      in_test_app_dir do
        unused_keys = expected_unused_keys.map { |k| ::I18n::Tasks::SplitKey.split_key(k, 2)[1] }
        initial_keys = i18n_task.data['en'].select_keys do |k, _node|
          unused_keys.none? { |unused_key| k.include?(unused_key) }
        end
        ENV['CONFIRM'] = '1'
        run_cmd 'remove-unused', '--keep-order'
        final_keys = i18n_task.data.reload['en'].select_keys do |k, _node|
          unused_keys.none? { |unused_key| k.include?(unused_key) }
        end
        expect(initial_keys.inspect).to eq(final_keys.inspect)
      end
    end
  end

  describe 'normalize' do
    it 'sorts the keys' do
      in_test_app_dir do
        run_cmd 'normalize'
        en_yml_data = i18n_task.data.reload['en'].select_keys do |_k, node|
          node.data[:path] == 'config/locales/en.yml'
        end
        expect(en_yml_data).to be_present
        en_yml_data.nodes do |nodes|
          next unless nodes.children

          keys = nodes.children.map(&:key)
          expect(keys).to eq keys.sort
        end
      end
    end

    it 'moves keys to the corresponding files as per data.write' do
      in_test_app_dir do
        expect(File).to_not exist 'config/locales/devise.en.yml'
        run_cmd 'normalize', '--pattern_router'
        expect(YAML.load_file('config/locales/devise.en.yml')['en']['devise']['a']).to eq 'EN_TEXT'
        # Old value should be removed
        expect(File).not_to exist 'config/locales/old_devise.en.yml'
      end
    end
  end

  describe 'add_missing' do
    it 'default placeholder: default_or_value_or_human_key' do
      in_test_app_dir do
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']).to be_nil
        expect(YAML.load_file('config/locales/en.yml')['en']['default_arg']).to be_nil
      end
      run_cmd 'add-missing', 'base'
      in_test_app_dir do
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']['key']).to eq 'Key'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'ES_TEXT'
        expect(YAML.load_file('config/locales/en.yml')['en']['default_arg']).to eq 'Default Text'
      end
    end

    it 'default value: base_value for non-base locale' do
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      end
      run_cmd 'add-missing', 'es'
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'EN_TEXT'
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es_plural_1']['a']['one']).to eq 'EN_TEXT'
      end
    end

    it '--value' do
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      end
      run_cmd 'normalize', '--pattern_router'
      run_cmd 'add-missing', '-v', 'TRME'
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME'
        expect(YAML.load_file('config/locales/devise.es.yml')['es']['devise']['a']).to eq 'ES_TEXT'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'TRME'
      end
    end

    it '--value with %{value}' do
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      end
      run_cmd 'add-missing', '-v', 'TRME %{value}'
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME EN_TEXT'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to eq 'TRME ES_TEXT'
      end
    end

    it '--value with %{key}' do
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      end
      run_cmd 'add-missing', '-v', 'TRME %{key}'
      in_test_app_dir do
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME es.missing_in_es.a'
        expect(YAML.load_file('config/locales/en.yml')['en']['present_in_es_but_not_en']['a']).to(
          eq 'TRME en.present_in_es_but_not_en.a'
        )
      end
    end
  end

  describe 'config' do
    it 'prints config' do
      expect(YAML.load(strip_ansi_escape(run_cmd('config')))).to(
        eq(in_test_app_dir { i18n_task.config_for_inspect })
      )
    end
  end

  describe 'find' do
    it 'prints usages' do
      result = strip_ansi_escape(run_cmd('find', 'used.*'))
      expect(result).to eq(<<~TXT)
        used.a 2
          app/views/usages.html.slim:1 p = t 'used.a'
          app/views/usages.html.slim:2 b = t 'used.a'
      TXT
    end

    it 'finds references' do
      result = strip_ansi_escape(run_cmd('find', 'reference*'))
      expect(result).to eq(<<~TXT)
        missing_target.a (resolved ref)
          app/views/index.html.slim:36 = t 'reference-missing-target.a'
        reference-missing-target (ref key)
          app/views/index.html.slim:36 = t 'reference-missing-target.a'
        reference-missing-target.a (ref)
          app/views/index.html.slim:36 = t 'reference-missing-target.a'
        reference-ok-nested (ref key)
          app/views/index.html.slim:35 = t 'reference-ok-nested.a'
        reference-ok-nested.a (ref)
          app/views/index.html.slim:35 = t 'reference-ok-nested.a'
        reference-ok-plain (ref key)
          app/views/index.html.slim:34 = t 'reference-ok-plain'
        resolved_reference_target.a (resolved ref)
          app/views/index.html.slim:35 = t 'reference-ok-nested.a'
      TXT
    end
  end

  # --- setup ---
  bench_keys_count = ENV['BENCH_KEYS'].to_i
  before(:each) do
    gen_data = lambda do |v|
      v_num = v.chars.map(&:ord).join.to_i
      {
        'ca' => { 'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}" },
        'cb' => { 'a' => v, 'b' => "#{v}%{i}" },
        'hash' => {
          'pattern' => { 'a' => v },
          'pattern2' => { 'a' => v },
          'pattern3' => { 'x' => { 'y' => { 'z' => v } } }
        },
        'unused' => { 'a' => v, 'numeric' => v_num, 'plural' => { 'one' => v, 'other' => v } },
        'ignore_unused' => { 'a' => v },
        'missing_in_es' => { 'a' => v },
        'missing_in_es_plural_1' => { 'a' => { 'one' => v, 'other' => v } },
        'missing_in_es_plural_2' => { 'a' => { 'one' => v, 'other' => v } },
        'same_in_es' => { 'a' => v },
        'ignore_eq_base_all' => { 'a' => v },
        'ignore_eq_base_es' => { 'a' => v },
        'blank_in_es' => { 'a' => v },
        'relative' => {
          'index' => {
            'title' => v,
            'description' => v,
            'summary' => v
          }
        },
        'numeric' => { 'a' => v_num },
        'plural' => { 'a' => { 'one' => v, 'other' => "%{count} #{v}s" } },
        'scoped' => { 'x' => v },
        'very' => { 'scoped' => { 'x' => v } },
        'used' => { 'a' => v },
        'latin_extra' => { 'çüéö' => v },
        'not_a_comment' => v,
        'reference-ok-plain' => :'resolved_reference_target.a',
        'reference-ok-nested' => :resolved_reference_target,
        'reference-unused' => :'resolved_reference_target.a',
        'reference-unused-target' => :'unused.a',
        'reference-missing-target' => :missing_target,
        'resolved_reference_target' => { 'a' => v }
      }.tap do |r|
        if bench_keys_count > 0
          gen = r['bench'] = {}
          bench_keys_count.times { |i| gen["key#{i}"] = v }
        end
      end
    end

    en_data = gen_data.call('EN_TEXT')
    es_data = gen_data.call('ES_TEXT').except('missing_in_es', 'missing_in_es_plural_1', 'missing_in_es_plural_2')

    # nil keys cannot be used, but the user might put them in by mistake
    # We should issue a warning and not blow up
    en_data[nil] = 'a warning is expected'

    es_data['same_in_es']['a']          = 'EN_TEXT'
    es_data['blank_in_es']['a']         = ''
    es_data['ignore_eq_base_all']['a']  = 'EN_TEXT'
    es_data['ignore_eq_base_es']['a']   = 'EN_TEXT'
    es_data['only_in_es']               = 1
    es_data['present_in_es_but_not_en'] = { 'a' => 'ES_TEXT' }

    fs = fixtures_contents.merge(
      'config/locales/en.yml' => { 'en' => en_data }.to_yaml,
      'config/locales/es.yml' => { 'es' => es_data }.to_yaml,
      'config/locales/external/en.yml' =>
          { 'en' => {
            'external' => {
              'used' => 'EN_TEXT', 'unused' => 'EN_TEXT', 'missing_in_es' => 'EN_TEXT'
            }
          } }.to_yaml,
      'config/locales/external/es.yml' =>
          { 'es' => { 'external' => { 'used' => 'ES_TEXT', 'unused' => 'ES_TEXT' } } }.to_yaml,
      'config/locales/old_devise.en.yml' => { 'en' => { 'devise' => { 'a' => 'EN_TEXT' } } }.to_yaml,
      'config/locales/old_devise.es.yml' => { 'es' => { 'devise' => { 'a' => 'ES_TEXT' } } }.to_yaml,
      'config/locales/unused.en.yml' => { 'en' => { 'unused' => { 'file' => 'EN_TEXT' } } }.to_yaml,
      'config/locales/unused.es.yml' => { 'es' => { 'unused' => { 'file' => 'ES_TEXT' } } }.to_yaml,
      'config/locales/not-in-write/unused.en.yml' =>
          { 'en' => { 'unused' => { 'not-in-write' => 'EN_TEXT' } } }.to_yaml,
      'config/locales/not-in-write/unused.es.yml' =>
          { 'es' => { 'unused' => { 'not-in-write' => 'ES_TEXT' } } }.to_yaml,
      # test that our algorithms can scale to the order of {bench_keys_count} keys.
      'vendor/heavy.file' => Array.new(bench_keys_count) { |i| "t('bench.key#{i}') " }.join
    )

    TestCodebase.setup fs
  end

  after do
    TestCodebase.teardown
  end
end
