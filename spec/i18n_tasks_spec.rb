# coding: utf-8
require 'spec_helper'
require 'i18n/tasks/commands'
require 'fileutils'

describe 'i18n-tasks' do
  delegate :run_cmd, :i18n_task, :in_test_app_dir, to: :TestCodebase

  describe 'missing' do
    let (:expected_missing_keys) {
      %w( en.used_but_missing.key en.relative.index.missing
          es.missing_in_es.a es.same_in_es.a
          en.hash.pattern_missing.a en.hash.pattern_missing.b
          en.missing_symbol_key en.missing_symbol.key_two en.missing_symbol.key_three
          es.missing_in_es_plural_1.a es.missing_in_es_plural_2.a
          en.missing-key-with-a-dash.key
        )
    }
    it 'detects missing or identical' do
      capture_stderr do
        expect(run_cmd :missing).to be_i18n_keys expected_missing_keys
        es_keys = expected_missing_keys.grep(/^es\./)
        # locale argument
        expect(run_cmd :missing, locales: %w(es)).to be_i18n_keys es_keys
        expect(run_cmd :missing, arguments: %w(es)).to be_i18n_keys es_keys
      end
    end
  end

  let(:expected_unused_keys) { %w(unused.a unused.numeric unused.plural) }
  describe 'unused' do
    it 'detects unused' do
      capture_stderr do
        expect(run_cmd :unused).to be_i18n_keys expected_unused_keys
      end
    end
  end

  describe 'remove_unused' do
    it 'removes unused' do
      in_test_app_dir do
        t = i18n_task
        expected_unused_keys.each do |key|
          expect(t.key_value?(key, :en)).to be true
          expect(t.key_value?(key, :es)).to be true
        end
        ENV['CONFIRM'] = '1'
        capture_stderr {
          run_cmd :remove_unused
        }
        t.data.reload
        expected_unused_keys.each do |key|
          expect(t.key_value?(key, :en)).to be false
          expect(t.key_value?(key, :es)).to be false
        end
      end
    end
  end

  describe 'normalize' do
    it 'moves keys to the corresponding files as per data.write' do
      in_test_app_dir {
        expect(File).to_not exist 'config/locales/devise.en.yml'
        run_cmd :normalize
        expect(YAML.load_file('config/locales/devise.en.yml')['en']['devise']['a']).to eq 'EN_TEXT'
      }
    end
  end

  describe 'xlsx_report' do
    it 'saves' do
      in_test_app_dir {
        capture_stderr { run_cmd :xlsx_report }
        expect(File).to exist 'tmp/i18n-report.xlsx'
        FileUtils.cp('tmp/i18n-report.xlsx', '..')
      }
    end

  end

  describe 'add_missing' do
    it 'default placeholder: key.humanize for base_locale' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']).to be_nil
      }
      run_cmd :add_missing, locales: 'base'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']['key']).to eq 'Key'
      }
    end

    it 'default placeholder: base_value for non-base locale' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :add_missing, locales: 'es'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'EN_TEXT'
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es_plural_1']['a']['one']).to eq 'EN_TEXT'
      }
    end

    it 'placeholder: value' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :add_missing, locales: 'all', placeholder: 'TRME'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME'
        # does not touch existing, but moves to the right file:
        expect(YAML.load_file('config/locales/devise.es.yml')['es']['devise']['a']).to eq 'ES_TEXT'
      }
    end

    it 'placeholder: value with base_value' do
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      run_cmd :add_missing, locales: 'all', placeholder: 'TRME %{base_value}'
      in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME EN_TEXT'
      }
    end
  end

  describe 'config' do
    it 'prints config' do
      expect(YAML.load(run_cmd :config)).to(
          eq(in_test_app_dir { i18n_task.config_for_inspect })
      )
    end
  end

  describe 'find' do
    it 'prints usages' do
      capture_stderr do
        expect(run_cmd :find, arguments: ['used.*']).to eq(<<-TXT)
used.a 2
  app/views/usages.html.slim:1 p = t 'used.a'
  app/views/usages.html.slim:2 b = t 'used.a'
TXT
      end
    end
  end


  # --- setup ---
  BENCH_KEYS = 100
  before(:each) do
    gen_data = ->(v) {
      v_num = v.chars.map(&:ord).join('').to_i
      {
        'ca'                  => {'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}"},
        'cb'                  => {'a' => v, 'b' => "#{v}%{i}"},
        'hash' => {
            'pattern'  => {'a' => v},
            'pattern2' => {'a' => v},
        },
        'unused'              => {'a' => v, 'numeric' => v_num, 'plural' => {'one' => v, 'other' => v}},
        'ignore_unused'       => {'a' => v},
        'missing_in_es'       => {'a' => v},
        'missing_in_es_plural_1' => { 'a' => {'one' => v, 'other' => v}},
        'missing_in_es_plural_2' => { 'a' => {'one' => v, 'other' => v}},
        'same_in_es'          => {'a' => v},
        'ignore_eq_base_all'  => {'a' => v},
        'ignore_eq_base_es'   => {'a' => v},
        'blank_in_es'         => {'a' => v},
        'relative'            => {
            'index' => {
                'title' => v,
                'description' => v,
                'summary' => v,
            }
        },
        'numeric'             => {'a' => v_num},
        'plural'              => {'a' => {'one' => v, 'other' => "%{count} #{v}s"}},
        'devise'              => {'a' => v},
        'scoped' => {'x' => v},
        'very'   => {'scoped' => {'x' => v}},
        'used'   => {'a' => v}
      }.tap { |r|
        gen = r["bench"] = {}
        BENCH_KEYS.times { |i| gen["key#{i}"] = v }
      }
    }

    en_data = gen_data.('EN_TEXT')
    es_data = gen_data.('ES_TEXT').except(
        'missing_in_es', 'missing_in_es_plural_1', 'missing_in_es_plural_2')
    es_data['same_in_es']['a']  = 'EN_TEXT'
    es_data['blank_in_es']['a'] = ''
    es_data['ignore_eq_base_all']['a'] = 'EN_TEXT'
    es_data['ignore_eq_base_es']['a']  = 'EN_TEXT'

    fs = fixtures_contents.merge(
      'config/locales/en.yml'                 => {'en' => en_data}.to_yaml,
      'config/locales/es.yml'                 => {'es' => es_data}.to_yaml,
      # test that our algorithms can scale to the order of {BENCH_KEYS} keys.
      'vendor/heavy.file' => BENCH_KEYS.times.map { |i| "t('bench.key#{i}') " }.join
    )

    TestCodebase.setup fs
  end

  after do
    TestCodebase.teardown
  end
end
