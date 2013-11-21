# coding: utf-8
require 'spec_helper'

describe 'rake i18n' do
  describe 'missing' do
    it 'detects missing or identical' do
      TestCodebase.capture_stderr do
        TestCodebase.rake_result('i18n:missing').should be_i18n_keys %w(en.used_but_missing.a en.index.missing_symbol_key es.missing_in_es.a es.blank_in_es.a es.same_in_es.a)
      end.should =~ /Missing keys and translations \(5\)/
    end
  end

  describe 'unused' do
    it 'detects unused' do
      TestCodebase.capture_stderr do
        TestCodebase.rake_result('i18n:unused').should be_i18n_keys %w(unused.a unused.numeric unused.plural)
      end.should =~ /Unused i18n keys \(3\)/
    end
  end

  describe 'prefill' do
    it 'prefills from en' do
      TestCodebase.in_test_app_dir { YAML.load_file('config/locales/es.yml')['es']['missing_in_es'].should be_nil }
      TestCodebase.rake_result('i18n:prefill')
      TestCodebase.in_test_app_dir {
        YAML.load_file('config/locales/es.yml')['es']['missing_in_es']['a'].should == 'EN_TEXT'
        YAML.load_file('config/locales/devise.en.yml')['en']['devise']['a'].should == 'EN_TEXT'
        YAML.load_file('config/locales/devise.es.yml')['es']['devise']['a'].should == 'ES_TEXT'
      }
    end
  end

  # --- setup ---
  BENCH_KEYS = 30
  before do
    gen_data = ->(v) {
      v_num = v.chars.map(&:ord).join('').to_i
      {
        'ca'                  => {'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}"},
        'cb'                  => {'a' => v, 'b' => "#{v}%{i}"},
        'hash_pattern'        => {'a' => v},
        'hash_pattern2'       => {'a' => v},
        'unused'              => {'a' => v, 'numeric' => v_num, 'plural' => {'one' => v, 'other' => v}},
        'ignore_unused'       => {'a' => v},
        'missing_in_es'       => {'a' => v},
        'same_in_es'          => {'a' => v},
        'ignore_eq_base_all'  => {'a' => v},
        'ignore_eq_base_es'   => {'a' => v},
        'blank_in_es'         => {'a' => v},
        'relative'            => {'index' => {'title' => v}},
        'numeric'             => {'a' => v_num},
        'plural'              => {'a' => {'one' => v, 'other' => "%{count} #{v}s"}},
        'devise'              => {'a' => v}
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
