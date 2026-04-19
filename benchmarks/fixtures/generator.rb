# frozen_string_literal: true

require "fileutils"
require "yaml"

# Generates synthetic but realistic i18n-tasks fixtures at three scales.
#
# Each scale produces:
#   - config/locales/<locale>.yml for each locale
#   - app/controllers/*.rb with I18n.t() calls
#   - app/views/**/*.html.erb with t() calls (relative and absolute)
#   - app/helpers/*.rb with mixed calls
#
# ~10% of keys in base locale are intentionally left out of other locales (missing).
# ~10% of defined keys are never referenced in source (unused).
module BenchmarkFixtures
  SCALES = {
    small: {num_keys: 200, num_rb_files: 15, num_erb_files: 15, num_locales: 2},
    medium: {num_keys: 2_000, num_rb_files: 100, num_erb_files: 100, num_locales: 5},
    large: {num_keys: 8_000, num_rb_files: 300, num_erb_files: 300, num_locales: 8}
  }.freeze

  LOCALES = %w[en es fr de ja zh pt it ko nl].freeze

  CONTROLLERS = %w[users posts comments orders products invoices sessions registrations
    profiles settings dashboards reports notifications search tags categories].freeze

  HELPERS = %w[application_helper users_helper posts_helper form_helper date_helper].freeze

  # Key sections that mirror realistic Rails apps
  SECTIONS = %w[
    users.index users.show users.new users.edit users.form
    posts.index posts.show posts.create posts.update posts.destroy
    comments.index comments.new comments.form
    orders.index orders.show orders.confirm orders.complete
    shared.errors shared.validations shared.navigation shared.buttons shared.labels
    mailers.welcome mailers.reset_password mailers.confirmation mailers.notification
    admin.users.index admin.users.show admin.posts.index admin.dashboard
    errors.not_found errors.unauthorized errors.server_error
    auth.login auth.logout auth.register auth.forgot_password
  ].freeze

  class << self
    def root
      File.expand_path("../..", __dir__)
    end

    def generated_root
      File.join(root, "benchmarks", "fixtures", "generated")
    end

    # Generate all fixtures.
    # @param force [Boolean] regenerate even if files already exist
    def generate_all(force: false)
      SCALES.each_key do |scale|
        generate(scale, force: force)
      end
    end

    # Generate fixtures for a single scale.
    # @param scale [:small, :medium, :large]
    # @param force [Boolean] regenerate even if files already exist
    # @return [String] path to the generated fixture directory
    def generate(scale, force: false)
      config = SCALES.fetch(scale)
      dir = File.join(generated_root, scale.to_s)

      sentinel = File.join(dir, ".generated")
      if !force && File.exist?(sentinel)
        return dir
      end

      FileUtils.rm_rf(dir)
      FileUtils.mkdir_p(dir)

      locales = LOCALES.first(config[:num_locales])
      base_locale = locales.first
      keys = generate_keys(config[:num_keys])

      write_config_file(dir, locales, base_locale)
      write_locale_files(dir, locales, base_locale, keys)
      write_ruby_files(dir, keys, config[:num_rb_files])
      write_erb_files(dir, keys, config[:num_erb_files], base_locale)

      FileUtils.touch(sentinel)
      dir
    end

    private

    # Build a flat list of dot-separated keys distributed across realistic sections.
    def generate_keys(count)
      keys = []
      per_section = [count / SECTIONS.size, 1].max
      SECTIONS.cycle do |section|
        break if keys.size >= count

        per_section.times do |i|
          break if keys.size >= count

          keys << "#{section}.key_#{i + 1}"
        end
      end
      keys.first(count)
    end

    def write_config_file(dir, locales, base_locale)
      FileUtils.mkdir_p(File.join(dir, "config"))

      config = {
        "base_locale" => base_locale,
        "locales" => locales,
        "data" => {
          "read" => ["config/locales/%{locale}.yml"],
          "write" => ["config/locales/%{locale}.yml"]
        },
        "search" => {
          "paths" => ["app/"],
          "relative_roots" => ["app/controllers", "app/helpers", "app/views"]
        }
      }

      File.write(File.join(dir, "config", "i18n-tasks.yml"), YAML.dump(config))
    end

    def write_locale_files(dir, locales, base_locale, keys)
      locale_dir = File.join(dir, "config", "locales")
      FileUtils.mkdir_p(locale_dir)

      locales.each do |locale|
        # Skip ~10% of keys for non-base locales to simulate missing translations.
        locale_keys = if locale == base_locale
          keys
        else
          keys.reject.with_index { |_, i| (i % 10).zero? }
        end

        # Mark ~10% of keys as "unused" by never referencing them in source.
        # We track unused indices and write them in the locale files but skip them in source.
        tree = keys_to_nested_hash(locale, locale_keys) { |key, i| "#{locale}.#{key}.value_#{i}" }
        File.write(File.join(locale_dir, "#{locale}.yml"), YAML.dump(tree))
      end
    end

    def keys_to_nested_hash(locale, keys)
      root = {locale => {}}
      keys.each_with_index do |key, i|
        parts = key.split(".")
        node = root[locale]
        parts[0..-2].each do |part|
          node[part] ||= {}
          node = node[part]
        end
        node[parts.last] = block_given? ? yield(key, i) : "#{locale}.#{key}"
      end
      root
    end

    # Write Ruby controller/helper files referencing ~90% of keys (leaving ~10% unused).
    def write_ruby_files(dir, keys, num_files)
      app_dir = File.join(dir, "app")
      FileUtils.mkdir_p(File.join(app_dir, "controllers"))
      FileUtils.mkdir_p(File.join(app_dir, "helpers"))

      # Keys that will be referenced from Ruby (skip every 10th = ~10% unused in source)
      source_keys = keys.reject.with_index { |_, i| (i % 10).zero? }
      keys_per_file = [source_keys.size / num_files, 1].max

      num_files.times do |n|
        file_keys = source_keys.slice(n * keys_per_file, keys_per_file) || []
        controller_name = "#{CONTROLLERS[n % CONTROLLERS.size]}_#{n}_controller"
        content = generate_ruby_file_content(controller_name, file_keys)

        if n < num_files / 2
          File.write(File.join(app_dir, "controllers", "#{controller_name}.rb"), content)
        else
          helper_name = "helper_#{n}"
          File.write(File.join(app_dir, "helpers", "#{helper_name}.rb"), content)
        end
      end
    end

    def generate_ruby_file_content(class_name, keys)
      lines = ["class #{camelize(class_name)} < ApplicationController"]
      lines << "  def index"
      keys.each_slice(3) do |slice|
        case rand(4)
        when 0
          lines << "    I18n.t(#{slice[0].inspect})"
          lines << "    I18n.t(#{slice[1].inspect})" if slice[1]
        when 1
          scope_parts = slice[0].split(".")
          lines << "    t(#{scope_parts.last.inspect}, scope: #{scope_parts[0..-2].inspect})"
        when 2
          lines << "    I18n.translate(#{slice[0].inspect})"
        else
          lines << "    t #{slice[0].inspect}"
          lines << "    t #{slice[1].inspect}" if slice[1]
        end
        lines << "    t #{slice[2].inspect}" if slice[2]
      end
      lines << "  end"

      # Add a method with dynamic key (exercises expr_key_re)
      if keys.any?
        section = keys.first.split(".").first(2).join(".")
        lines << "  def show"
        lines << "    # dynamic key - should not count as unused"
        lines << "    t(\"#{section}.\#{some_dynamic_value}\")"
        lines << "  end"
      end

      lines << "end"
      lines.join("\n")
    end

    # Write ERB view files with relative t() calls and some absolute ones.
    def write_erb_files(dir, keys, num_files, _base_locale)
      views_dir = File.join(dir, "app", "views")

      # Use only non-"unused" keys in views to keep ~10% unused
      source_keys = keys.reject.with_index { |_, i| (i % 10).zero? }
      keys_per_file = [source_keys.size / [num_files, 1].max, 1].max

      num_files.times do |n|
        file_keys = source_keys.slice(n * keys_per_file, keys_per_file) || []
        section = file_keys.first&.split(".")&.first(2)&.join("/") || "shared"
        FileUtils.mkdir_p(File.join(views_dir, section))

        content = generate_erb_file_content(file_keys)
        File.write(File.join(views_dir, section, "view_#{n}.html.erb"), content)
      end
    end

    def generate_erb_file_content(keys)
      lines = ["<div>"]
      keys.each_with_index do |key, i|
        case i % 3
        when 0
          lines << "  <%= t(#{key.inspect}) %>"
        when 1
          # relative key - use just the last segment
          leaf = key.split(".").last
          lines << "  <%= t(#{".#{leaf}".inspect}) %>"
        else
          lines << "  <%= I18n.t(#{key.inspect}) %>"
        end
      end
      lines << "</div>"
      lines.join("\n")
    end

    def camelize(str)
      str.split(/[_\/]/).map(&:capitalize).join
    end
  end
end
