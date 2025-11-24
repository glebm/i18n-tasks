#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate benchmark fixture data
# Usage: ruby benchmark/generate_fixtures.rb
#   Generates 500 files with ~15000 keys

require "fileutils"

class BenchmarkFixtureGenerator
  FIXTURES_DIR = "benchmark/fixtures"

  def initialize
    @files = 500
    @keys_per_file = 30
  end

  def generate
    puts "Generating benchmark fixtures: #{@files} files, ~#{@files * @keys_per_file} keys"
    puts "=" * 60

    FileUtils.mkdir_p(FIXTURES_DIR)
    clean_fixtures

    generate_config
    generate_locales
    generate_ruby_files
    generate_erb_files
    generate_controllers
    generate_views
    generate_haml_files
    generate_slim_files
    generate_js_files
    generate_vue_files
    generate_jsx_files

    puts "\n✓ Fixtures generated in #{FIXTURES_DIR}/"
  end

  private

  def clean_fixtures
    FileUtils.rm_rf(Dir.glob("#{FIXTURES_DIR}/*"))
  end

  def generate_config
    config = <<~YAML
      base_locale: en
      locales: [en, es, fr, de]

      data:
        read:
          - config/locales/**/*.yml
        write:
          - config/locales/%{locale}.yml

      search:
        paths:
          - app/
        exclude:
          - tmp/
    YAML

    write_file("config/i18n-tasks.yml", config)
    puts "  ✓ Config file"
  end

  def generate_locales
    locales = {
      en: generate_locale_data("en"),
      es: generate_locale_data("es"),
      fr: generate_locale_data("fr"),
      de: generate_locale_data("de")
    }

    locales.each do |locale, data|
      write_file("config/locales/#{locale}.yml", data)
    end
    puts "  ✓ Locale files (4 locales)"
  end

  def generate_locale_data(locale)
    total_keys = @files * @keys_per_file

    data = {locale => {}}

    # Generate nested structure
    (1..total_keys).each do |i|
      category = "category_#{(i - 1) / 10 + 1}"
      data[locale][category] ||= {}
      data[locale][category]["key_#{i}"] = "#{locale.upcase} Translation #{i}"
    end

    require "yaml"
    data.to_yaml
  end

  def generate_ruby_files
    models_count = @files / 5

    (1..models_count).each do |i|
      content = generate_ruby_model(i)
      write_file("app/models/model_#{i}.rb", content)
    end

    puts "  ✓ Ruby models (#{models_count} files)"
  end

  def generate_ruby_model(index)
    keys_per_file = @keys_per_file

    <<~RUBY
      # frozen_string_literal: true

      class Model#{index}
        def self.translations
          {
      #{(1..keys_per_file).map { |i|
        key_num = (index - 1) * keys_per_file + i
        category = "category_#{(key_num - 1) / 10 + 1}"
        "      key_#{i}: I18n.t('#{category}.key_#{key_num}')"
      }.join(",\n")}
          }
        end

        def instance_translation
          I18n.t('category_#{index}.key_#{index}')
        end

        def dynamic_translation(key)
          I18n.t("category_#{index}.\#{key}")
        end
      end
    RUBY
  end

  def generate_erb_files
    view_count = @files / 5

    (1..view_count).each do |i|
      content = generate_erb_view(i)
      write_file("app/views/items/view_#{i}.html.erb", content)
    end

    puts "  ✓ ERB views (#{view_count} files)"
  end

  def generate_erb_view(index)
    keys_per_file = @keys_per_file

    lines = ["<div class=\"container\">"]

    (1..keys_per_file).each do |i|
      key_num = (index - 1) * keys_per_file + i
      category = "category_#{(key_num - 1) / 10 + 1}"

      lines << "  <h#{(i % 3) + 1}><%= t('#{category}.key_#{key_num}') %></h#{(i % 3) + 1}>"

      if i % 3 == 0
        lines << "  <p><%= t '#{category}.key_#{key_num}', default: 'Default text' %></p>"
      end
    end

    lines << "</div>"
    lines.join("\n")
  end

  def generate_controllers
    controller_count = @files / 5

    (1..controller_count).each do |i|
      content = generate_controller(i)
      write_file("app/controllers/controller_#{i}.rb", content)
    end

    puts "  ✓ Controllers (#{controller_count} files)"
  end

  def generate_controller(index)
    keys_per_file = [@keys_per_file / 2, 3].max

    <<~RUBY
      # frozen_string_literal: true

      class Controller#{index} < ApplicationController
        def index
          @title = t('category_#{index}.key_#{index}')
      #{(2..keys_per_file).map { |i|
        key_num = (index - 1) * keys_per_file + i
        category = "category_#{(key_num - 1) / 10 + 1}"
        "    @message_#{i} = t('#{category}.key_#{key_num}')"
      }.join("\n")}
        end

        def show
          flash[:notice] = t('category_#{index}.key_#{index}')
        end
      end
    RUBY
  end

  def generate_views
    # Generate some complex nested views
    view_count = [@files / 10, 5].max

    (1..view_count).each do |i|
      content = generate_complex_view(i)
      write_file("app/views/complex/nested_#{i}.html.erb", content)
    end

    puts "  ✓ Complex views (#{view_count} files)"
  end

  def generate_complex_view(index)
    <<~ERB
      <div class="complex-view">
        <%= render partial: 'header', locals: { title: t('category_#{index}.key_#{index}') } %>

        <% items = [1, 2, 3] %>
        <% items.each do |item| %>
          <div class="item">
            <%= t("category_#{index}.key_\#{item}") %>
          </div>
        <% end %>

        <% if user_signed_in? %>
          <%= t('category_#{index}.key_#{index + 1}') %>
        <% else %>
          <%= t('category_#{index}.key_#{index + 2}') %>
        <% end %>

        <%= form_for @object do |f| %>
          <%= f.label :name, t('category_#{index}.key_#{index + 3}') %>
          <%= f.text_field :name, placeholder: t('category_#{index}.key_#{index + 4}') %>
        <% end %>
      </div>
    ERB
  end

  def generate_haml_files
    haml_count = @files / 10

    (1..haml_count).each do |i|
      content = generate_haml_view(i)
      write_file("app/views/haml/view_#{i}.html.haml", content)
    end

    puts "  ✓ HAML views (#{haml_count} files)"
  end

  def generate_haml_view(index)
    keys_per_file = @keys_per_file

    lines = ["#container"]

    (1..keys_per_file).each do |i|
      key_num = (index - 1) * keys_per_file + i
      category = "category_#{(key_num - 1) / 10 + 1}"

      lines << case i % 4
      when 0
        "  %h#{(i % 3) + 1}= t('#{category}.key_#{key_num}')"
      when 1
        "  .content{ title: t('#{category}.key_#{key_num}') }"
      when 2
        "  %p= t '#{category}.key_#{key_num}', default: 'Default'"
      else
        "  = t('#{category}.key_#{key_num}')"
      end
    end

    lines.join("\n")
  end

  def generate_slim_files
    slim_count = @files / 10

    (1..slim_count).each do |i|
      content = generate_slim_view(i)
      write_file("app/views/slim/view_#{i}.html.slim", content)
    end

    puts "  ✓ Slim views (#{slim_count} files)"
  end

  def generate_slim_view(index)
    keys_per_file = @keys_per_file

    lines = ["div.container"]

    (1..keys_per_file).each do |i|
      key_num = (index - 1) * keys_per_file + i
      category = "category_#{(key_num - 1) / 10 + 1}"

      lines << case i % 4
      when 0
        "  h#{(i % 3) + 1} = t('#{category}.key_#{key_num}')"
      when 1
        "  p = t '#{category}.key_#{key_num}'"
      when 2
        "  span[title=t('#{category}.key_#{key_num}')] Content"
      else
        "  = t('#{category}.key_#{key_num}')"
      end
    end

    lines.join("\n")
  end

  def generate_js_files
    js_count = @files / 15

    (1..js_count).each do |i|
      content = generate_js_file(i)
      write_file("app/javascript/components/component_#{i}.js", content)
    end

    puts "  ✓ JavaScript files (#{js_count} files)"
  end

  def generate_js_file(index)
    keys_per_file = [@keys_per_file / 2, 3].max

    lines = ["// Component #{index}", "import I18n from 'i18n-js';\n"]
    lines << "export default class Component#{index} {"
    lines << "  constructor() {"

    (1..keys_per_file).each do |i|
      key_num = (index - 1) * keys_per_file + i
      category = "category_#{(key_num - 1) / 10 + 1}"
      lines << "    this.message#{i} = I18n.t('#{category}.key_#{key_num}');"
    end

    lines << "  }\n"
    lines << "  render() {"
    lines << "    return I18n.t('category_#{index}.key_#{index}');"
    lines << "  }"
    lines << "}"

    lines.join("\n")
  end

  def generate_vue_files
    vue_count = @files / 15

    (1..vue_count).each do |i|
      content = generate_vue_component(i)
      write_file("app/javascript/components/Component#{i}.vue", content)
    end

    puts "  ✓ Vue components (#{vue_count} files)"
  end

  def generate_vue_component(index)
    keys_per_file = [@keys_per_file / 2, 3].max

    <<~VUE
      <template>
        <div class="component-#{index}">
          <h1>{{ $t('category_#{index}.key_#{index}') }}</h1>
      #{(2..keys_per_file).map { |i|
        key_num = (index - 1) * keys_per_file + i
        category = "category_#{(key_num - 1) / 10 + 1}"
        "    <p>{{ $t('#{category}.key_#{key_num}') }}</p>"
      }.join("\n")}
        </div>
      </template>

      <script>
      export default {
        name: 'Component#{index}',
        computed: {
          title() {
            return this.$t('category_#{index}.key_#{index}');
          }
        }
      };
      </script>
    VUE
  end

  def generate_jsx_files
    jsx_count = @files / 15

    (1..jsx_count).each do |i|
      content = generate_jsx_component(i)
      write_file("app/javascript/components/Component#{i}.jsx", content)
    end

    puts "  ✓ JSX/React components (#{jsx_count} files)"
  end

  def generate_jsx_component(index)
    keys_per_file = [@keys_per_file / 2, 3].max

    <<~JSX
      import React from 'react';
      import { useTranslation } from 'react-i18next';

      export default function Component#{index}() {
        const { t } = useTranslation();

        return (
          <div className="component-#{index}">
            <h1>{t('category_#{index}.key_#{index}')}</h1>
      #{(2..keys_per_file).map { |i|
        key_num = (index - 1) * keys_per_file + i
        category = "category_#{(key_num - 1) / 10 + 1}"
        "      <p>{t('#{category}.key_#{key_num}')}</p>"
      }.join("\n")}
          </div>
        );
      }
    JSX
  end

  def write_file(path, content)
    full_path = File.join(FIXTURES_DIR, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end

if __FILE__ == $PROGRAM_NAME
  generator = BenchmarkFixtureGenerator.new
  generator.generate
end
