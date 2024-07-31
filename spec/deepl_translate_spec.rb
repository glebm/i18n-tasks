# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks/commands'
require 'deepl'

RSpec.describe 'DeepL Translation' do
  nil_value_test = ['nil-value-key', nil, nil]

  text_test = [
    'key',
    "Hello, %{user} O'Neill! How are you? {{ Check out this Liquid tag, it should not be translated }} " \
    '{% That applies to this Liquid tag as well %}',
    "¡Hola, %{user} O'Neill! ¿Qué tal? {{ Check out this Liquid tag, it should not be translated }} " \
    '{% That applies to this Liquid tag as well %}'
  ]

  html_test_plrl = [
    'html-key.html.one', '<span>Hello %{count} {{ count }} {% count %}</span>',
    '<span>Hola %{count} {{ count }} {% count %}</span>'
  ]
  array_test      = ['array-key', ['Hello.', nil, '', 'Goodbye.'], ['Hola.', nil, '', 'Adiós.']]
  array_hash_test = ['array-hash-key',
                     [{ 'hash_key1' => 'How are you?' }, { 'hash_key2' => nil }, { 'hash_key3' => 'Well.' }],
                     [{ 'hash_key1' => '¿Qué tal?' }, { 'hash_key2' => nil }, { 'hash_key3' => 'Bien.' }]]
  fixnum_test     = ['numeric-key', 1, 1]
  ref_key_test    = ['ref-key', :reference, :reference]
  # this test fails atm due to moving of the bold tag =>  "Hola, <b>%{user} </b> gran O'neill ❤︎ "
  # it could be a bug, but the api also allows to ignore certain tags and there is the new html-markup version which
  # could be used too
  html_test       = ['html-key.html', "Hello, <b>%{user} big O'neill</b> ❤︎", "Hola, <b>%{user} gran O'neill</b> ❤︎"]
  support_test    = ['support', '%{model} or similar', '%{model} o similar']

  describe 'real world test' do
    delegate :i18n_task, :in_test_app_dir, :run_cmd, to: :TestCodebase

    before do
      TestCodebase.setup('config/locales/en.yml' => '', 'config/locales/es.yml' => '')
    end

    after do
      TestCodebase.teardown
    end

    context 'command' do
      let(:task) { i18n_task }

      it 'works' do # rubocop:disable RSpec/MultipleExpectations
        skip 'temporarily disabled on JRuby due to https://github.com/jruby/jruby/issues/4802' if RUBY_ENGINE == 'jruby'
        skip 'DEEPL_AUTH_KEY env var not set' unless ENV['DEEPL_AUTH_KEY']
        in_test_app_dir do
          task.data[:en] = build_tree('en' => {
                                        'common' => {
                                          'a' => 'λ',
                                          'hello' => text_test[1],
                                          'hello_html' => html_test[1],
                                          'hello_plural_html' => {
                                            'one' => html_test_plrl[1]
                                          },
                                          'array_key' => array_test[1],
                                          'array_hash_key' => array_hash_test[1],
                                          'nil-value-key' => nil_value_test[1],
                                          'fixnum-key' => fixnum_test[1],
                                          'ref-key' => ref_key_test[1],
                                          'support' => support_test[1],
                                          'needs_escaping' => 'Cars << Trucks / %{keep_this}',
                                          'needs_escaping_html' => '<span>Cars</span> << Trucks / %{keep_this}'
                                        }
                                      })
          task.data[:es] = build_tree('es' => {
                                        'common' => {
                                          'a' => 'λ'
                                        }
                                      })

          run_cmd 'translate-missing', '--backend=deepl'
          expect(task.t('common.hello', 'es')).to eq(text_test[2])
          expect(task.t('common.hello_plural_html.one', 'es')).to eq(html_test_plrl[2])
          expect(task.t('common.array_key', 'es')).to eq(array_test[2])
          expect(task.t('common.nil-value-key', 'es')).to eq(nil_value_test[2])
          expect(task.t('common.fixnum-key', 'es')).to eq(fixnum_test[2])
          expect(task.t('common.ref-key', 'es')).to eq(ref_key_test[2])
          expect(task.t('common.a', 'es')).to eq('λ')
          expect(task.t('common.hello_html', 'es')).to eq(html_test[2])
          expect(task.t('common.support', 'es')).to eq(support_test[2])
          expect(task.t('common.needs_escaping', 'es')).to eq('Coches << Camiones / %{keep_this}')
          # The << is automatically escaped when calling the translation service
          expect(
            task.t('common.needs_escaping_html', 'es')
          ).to eq('<span>Coches</span> &lt;&lt; Camiones / %{keep_this}')
        end
      end
    end
  end

  # Don't expect deepl's answers to be exactly the same each run
  describe 'translating Dutch into other languages' do
    let(:base_task) { I18n::Tasks::BaseTask.new }

    before do
      skip 'temporarily disabled on JRuby due to https://github.com/jruby/jruby/issues/4802' if RUBY_ENGINE == 'jruby'
      skip 'DEEPL_AUTH_KEY env var not set' unless ENV['DEEPL_AUTH_KEY']
    end

    it 'tells time' do
      german, english, spanish =
        translate_dutch(hours_and_minutes: '%{hours} uur en %{minutes} minuten')
      expect(german).to eq '%{hours} Stunden und %{minutes} Minuten'
      expect(english).to eq '%{hours} hours and %{minutes} minutes'
      expect(spanish).to eq '%{hours} horas y %{minutes} minutos'
    end

    it 'counts' do
      german, english, spanish =
        translate_dutch(other: '%{count} taken')
      expect(german).to eq '%{count} Aufgaben'
      expect(english).to eq '%{count} tasks'
      expect(spanish).to eq '%{count} tareas'
    end

    it 'assigns' do
      german, english, spanish =
        translate_dutch(assigned: 'Taak "%{todo}" toegewezen aan %{user}')
      expect(german).to eq 'To-dos "%{todo}" zugewiesen an %{user}'
      expect(english).to eq 'Task "%{todo}" assigned to %{user}'
      expect(spanish).to eq 'Tarea "%{todo}" asignada a %{user}'
    end

    it 'sings' do
      german, english, spanish =
        translate_dutch(verse: 'Ik zou zo graag een %{animal} kopen. Ik zag %{count} beren %{food} smeren')
      expect(german).to eq 'Ich würde so gerne einen %{animal} kaufen. Ich sah %{count} Bären, die %{food} schmierten'
      # greasing is a funny way to say smeren, but we let it slide
      expect(english).to eq 'I would so love to buy a %{animal}. I saw %{count} bears greasing %{food}'
      expect(spanish).to eq 'Me encantaría comprar un %{animal}. Vi %{count} osos engrasando %{food}'
    end

    it 'sends emails' do
      german, english, spanish =
        translate_dutch(
          email_body_html: '{{ booking.greeting }},<br><br>Bijgevoegd ziet u een factuur van {{ park.name }} met ' \
                           'factuurnummer {{ invoice.invoice_nr }}.<br />Volgens onze administratie had het ' \
                           'verschuldigde bedrag van {{ locals.payment_collector_total }} op  ' \
                           '{{ locals.payment_collector_deadline }} moeten zijn betaald. Helaas hebben we nog ' \
                           'geen betaling ontvangen.<br>'
        )
      expect(german).to eq '{{ booking.greeting }},<br /><br />Anbei finden Sie eine Rechnung von {{ park.name }} ' \
                           'mit der Rechnungsnummer {{ invoice.invoice_nr }}.<br />Laut unserer Verwaltung hätte der ' \
                           'von {{ locals.payment_collector_total }} geschuldete Betrag ' \
                           'am {{ locals.payment_collector_deadline }} bezahlt werden müssen. Leider haben wir die ' \
                           'Zahlungen noch nicht erhalten.<br />'
      expect(english).to eq '{{ booking.greeting }},<br /><br />Attached please find an invoice from {{ park.name }} ' \
                            'with invoice number {{ invoice.invoice_nr }}.<br />According to our records, the amount ' \
                            'due from {{ locals.payment_collector_total }} on ' \
                            '{{ locals.payment_collector_deadline }} should have been paid. Unfortunately, we have ' \
                            'not yet received payment.<br />'
      expect(spanish).to eq '{{ booking.greeting }},<br /><br />Adjuntamos una factura de {{ park.name }} con el ' \
                            'número de factura {{ invoice.invoice_nr }}.<br />Según nuestros registros, el importe ' \
                            'adeudado por {{ locals.payment_collector_total }} debería haber sido abonado en ' \
                            '{{ locals.payment_collector_deadline }}. Lamentablemente, aún no hemos recibido ' \
                            'el pago.<br />'
    end

    it 'asks itself why are you even translating this' do
      german, english, spanish =
        translate_dutch(action: '%{subject} %{verb} %{object}')
      expect(german).to eq '%{subject} %{verb} %{object}'
      expect(english).to eq '%{subject} %{verb} %{object}'
      expect(spanish).to eq '%{subject} %{verb} %{object}'
    end

    def translate_dutch(dutch_pair)
      key = dutch_pair.keys.first
      phrase = dutch_pair[key]
      locales = %w[de en-us es]
      branches = locales.each_with_object({}) do |locale, hash|
        hash[locale] = { 'testing' => { key => phrase } }
      end
      tree = build_tree(branches)
      translations = base_task.translate_forest(tree, from: 'nl', backend: :deepl)
      locales.map { |locale| translations[locale]['testing'][key].value.strip }
    end
  end
end
