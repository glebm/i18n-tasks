# coding: utf-8
require 'spec_helper'

describe 'rake i18n' do
  describe 'missing' do
    it 'detects missing or identical' do
      TestCodebase.capture_stderr do
        TestCodebase.rake_result('i18n:missing').should be_i18n_keys %w(en.used_but_missing.a es.missing_in_es.a es.blank_in_es.a es.same_in_es.a)
      end.should =~ /Missing keys and translations \(4\)/
    end
  end

  describe 'unused' do
    it 'detects unused' do
      TestCodebase.capture_stderr do
        TestCodebase.rake_result('i18n:unused').should be_i18n_keys %w(unused.a)
      end.should =~ /Unused i18n keys \(1\)/
    end
  end

  describe 'prefill' do
    it 'detects unused' do
      TestCodebase.in_test_app_dir { YAML.load_file('config/locales/es.yml')['es']['missing_in_es'].should be_nil }
      TestCodebase.rake_result('i18n:prefill')
      TestCodebase.in_test_app_dir { YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a'].should == 'EN_TEXT' }
    end
  end

  # --- setup ---
  BENCH_KEYS = 30
  before do
    gen_data = ->(v) {
      {
        'ca'                  => {'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}"},
        'cb'                  => {'a' => v, 'b' => "#{v}%{i}"},
        'hash_pattern'        => {'a' => v},
        'hash_pattern2'       => {'a' => v},
        'unused'              => {'a' => v},
        'ignore_unused'       => {'a' => v},
        'missing_in_es'       => {'a' => v},
        'same_in_es'          => {'a' => v},
        'ignore_eq_base_all'  => {'a' => v},
        'ignore_eq_base_es'   => {'a' => v},
        'blank_in_es'         => {'a' => v},
        'relative'            => {'index' => {'title' => v}}
      }.tap {|r|
        gen = r["bench"] = {}
        BENCH_KEYS.times {|i| gen["key#{i}"] = v }
      }
    }

    en_data = gen_data.('EN_TEXT')
    es_data = gen_data.('ES_TEXT').except('missing_in_es')
    es_data['same_in_es']['a']  = 'EN_TEXT'
    es_data['blank_in_es']['a'] = ''
    es_data['ignore_eq_base_all']['a'] = 'EN_TEXT'
    es_data['ignore_eq_base_es']['a']  = 'EN_TEXT'

    fs = {
      'config/locales/en.yml'                 => {'en' => en_data}.to_yaml,
      'config/locales/es.yml'                 => {'es' => es_data}.to_yaml,
      'config/i18n-tasks.yml'                 => load_fixture('config/i18n-tasks.yml'),
      'app/views/index.html.slim'             => load_fixture('app/views/index.html.slim'),
      'app/views/relative/index.html.slim'    => load_fixture('app/views/relative/index.html.slim'),
      'app/controllers/events_controller.rb'  => load_fixture('app/controllers/events_controller.rb'),
      'app/assets/javascripts/application.js' => load_fixture('app/assets/javascripts/application.js'),

      # test that our algorithms can scale to the order of {BENCH_KEYS} keys.
      'vendor/heavy.file' => BENCH_KEYS.times.map { |i| "t('bench.key#{i}') " }.join
    }
    TestCodebase.setup fs
  end

  after do
    TestCodebase.teardown
  end
end
