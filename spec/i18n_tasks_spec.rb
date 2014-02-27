# coding: utf-8
require 'spec_helper'
require 'fileutils'

describe 'rake i18n' do
  describe 'missing' do
    it 'detects missing or identical' do
      capture_stderr do
        expect(TestCodebase.rake_result('i18n:missing')).to be_i18n_keys %w(
          en.used_but_missing.a en.relative.index.missing
          es.missing_in_es.a es.blank_in_es.a es.same_in_es.a
          en.hash.pattern_missing.a en.hash.pattern_missing.b
          en.missing_symbol_key en.missing_symbol.key_two en.missing_symbol.key_three
        )
      end
    end
  end

  describe 'unused' do
    let(:expected_unused_keys) { %w(unused.a unused.numeric unused.plural) }

    it 'detects unused' do
      capture_stderr do
        out = TestCodebase.rake_result('i18n:unused')
        expect(out).to be_i18n_keys expected_unused_keys
      end
    end

    it 'removes unused' do
      TestCodebase.in_test_app_dir do
        t = I18n::Tasks::BaseTask.new
        expected_unused_keys.each do |key|
          expect(t.key_value?(key, :en)).to be_true
          expect(t.key_value?(key, :es)).to be_true
        end
        ENV['CONFIRM'] = '1'
        capture_stderr {
          TestCodebase.rake_result('i18n:remove_unused')
        }
        t.data.reload
        expected_unused_keys.each do |key|
          expect(t.key_value?(key, :en)).to be_false
          expect(t.key_value?(key, :es)).to be_false
        end
      end
    end
  end

  describe 'normalize' do
    it 'moves keys to the corresponding files as per data.write' do
      TestCodebase.in_test_app_dir {
        expect(File).to_not exist 'config/locales/devise.en.yml'
        TestCodebase.rake_result('i18n:normalize')
        expect(YAML.load_file('config/locales/devise.en.yml')['en']['devise']['a']).to eq 'EN_TEXT'
      }
    end
  end

  describe 'spreadsheet report' do
    it 'saves' do
      TestCodebase.in_test_app_dir {
        capture_stderr { TestCodebase.rake_result('i18n:spreadsheet_report') }
        expect(File).to exist 'tmp/i18n-report.xlsx'
        FileUtils.cp('tmp/i18n-report.xlsx', '..')
      }
    end

  end

  describe 'add_missing' do
    it 'placeholder' do
      TestCodebase.in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']).to be_nil
      }
      TestCodebase.rake_result('i18n:add_missing:placeholder', 'base')
      TestCodebase.in_test_app_dir {
        expect(YAML.load_file('config/locales/en.yml')['en']['used_but_missing']['a']).to eq 'A'
      }
    end

    it 'placeholder[VALUE]' do
      TestCodebase.in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']).to be_nil
      }
      TestCodebase.rake_result('i18n:add_missing:placeholder', 'all', 'TRME')
      TestCodebase.in_test_app_dir {
        expect(YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a']).to eq 'TRME'
        # does not touch existing, but moves to the right file:
        expect(YAML.load_file('config/locales/devise.es.yml')['es']['devise']['a']).to eq 'ES_TEXT'
      }
    end
  end

  describe 'tasks_config' do
    it 'prints config' do
      expect(YAML.load(TestCodebase.rake_result('i18n:tasks_config'))).to(
          eq TestCodebase.in_test_app_dir { I18n::Tasks::BaseTask.new.config_for_inspect }
      )
    end
  end

  describe 'usages' do
    it 'prints usages' do
      capture_stderr do
        expect(TestCodebase.rake_result('i18n:usages', 'used.*')).to eq(<<-TXT)
used.a 2
  app/views/usages.html.slim:1 p = t 'used.a'
  app/views/usages.html.slim:2 b = t 'used.a'
TXT
      end
    end
  end


  # --- setup ---
  BENCH_KEYS = 100
  before do
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
    es_data = gen_data.('ES_TEXT').except('missing_in_es')
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
