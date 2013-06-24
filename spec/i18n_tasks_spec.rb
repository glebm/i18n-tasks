require 'spec_helper'

describe 'rake i18n' do
  describe 'missing' do
    it 'detects missing or identical' do
      TestCodebase.rake_result('i18n:missing').should be_i18n_keys %w(es.missing_in_es.a es.blank_in_es.a es.same_in_es.a)
    end
  end

  describe 'unused' do
    it 'detects unused' do
      TestCodebase.rake_result('i18n:unused').should be_i18n_keys %w(unused.a)
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
  before do
    gen_data = ->(v) {
      {
          'ca'            => {'a' => v, 'b' => v, 'c' => v, 'd' => v, 'e' => "#{v}%{i}", 'f' => "#{v}%{i}"},
          'cb'            => {'a' => v, 'b' => "#{v}%{i}"},
          'hash_pattern'  => {'a' => v},
          'hash_pattern2' => {'a' => v},
          'unused'        => {'a' => v},
          'missing_in_es' => {'a' => v},
          'same_in_es'    => {'a' => v},
          'blank_in_es'   => {'a' => v}
      }
    }

    en_data                          = gen_data.('EN_TEXT')
    es_data                          = gen_data.('ES_TEXT').except('missing_in_es')
    es_data['same_in_es']['a'] = 'EN_TEXT'
    es_data['blank_in_es']['a']      = ''

    fs = {
        'config/locales/en.yml'     => {'en' => en_data}.to_yaml,
        'config/locales/es.yml'     => {'es' => es_data}.to_yaml,
        'app/views/index.html.slim' => <<-SLIM,
        p \#{t('ca.a')} \#{t 'ca.b'} \#{t "ca.c"}
        p \#{t 'ca.d'} \#{t 'ca.f', i: 'world'} \#{t 'ca.e', i: 'world'}
        p \#{t 'missing_in_es.a'} \#{t 'same_in_es.a'} \#{t 'blank_in_es.a'}
        SLIM
        'app/controllers/events_controller.slim' => <<-RUBY,
        class EventsController < ApplicationController
           def show
              redirect_to :edit, notice: I18n.t('cb.a')
              I18n.t("cb.b", i: "Hello")
              I18n.t("hash_pattern.\#{some_value}", i: "Hello")
              I18n.t("hash_pattern2." + some_value, i: "Hello")
           end
        end
        RUBY
    }
    TestCodebase.setup fs
  end

  after do
    TestCodebase.teardown
  end
end
