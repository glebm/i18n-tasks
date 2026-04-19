# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "memory_profiler"

# Load the gem under test
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "i18n/tasks"

require_relative "fixtures/generator"

BENCH_ROOT = File.expand_path("..", __dir__)

module BenchHelper
  # Generate all fixture scales (idempotent - reads from cache unless forced).
  def self.prepare_fixtures(force: false)
    BenchmarkFixtures.generate_all(force: force)
  end

  # Build a configured I18n::Tasks::BaseTask context pointed at a fixture directory.
  #
  # @param scale [:small, :medium, :large]
  # @return [I18n::Tasks::BaseTask]
  def self.build_context(scale)
    dir = BenchmarkFixtures.generate(scale)
    config_file = File.join(dir, "config", "i18n-tasks.yml")
    Dir.chdir(dir) do
      I18n::Tasks::BaseTask.new(config_file: config_file)
    end
  end

  # Run a block with working directory set to the fixture dir.
  # The context is created fresh each time so memoized caches don't carry over.
  def self.in_fixture_dir(scale)
    dir = BenchmarkFixtures.generate(scale)
    Dir.chdir(dir) { yield }
  end

  # Pre-warm the context so file-system caches are hot before timing.
  def self.warm_context(context)
    context.used_tree
    context
  rescue
    context
  end

  # Print a section header.
  def self.header(title)
    puts
    puts "=" * 60
    puts "  #{title}"
    puts "=" * 60
    puts
  end

  # Save IPS results to a JSON file for baseline comparison.
  #
  # @param suite [Benchmark::IPS::Suite] the completed suite
  # @param label [String] top-level key in the JSON object
  # @param path [String] path to the results JSON file
  def self.save_results(suite, label, path: File.join(BENCH_ROOT, "benchmarks", "results", "baseline.json"))
    require "json"
    FileUtils.mkdir_p(File.dirname(path))
    existing = File.exist?(path) ? JSON.parse(File.read(path)) : {}
    existing[label] ||= {}
    suite.entries.each do |entry|
      existing[label][entry.label] = {
        ips: entry.stats.central_tendency.round(2),
        ips_sd: entry.stats.error.round(2),
        microseconds: (1_000_000.0 / entry.stats.central_tendency).round(2)
      }
    end
    File.write(path, JSON.pretty_generate(existing))
    puts "Results saved to #{path}"
  end

  # Compare an IPS suite against a stored baseline and warn about regressions.
  #
  # @param suite [Benchmark::IPS::Suite]
  # @param label [String]
  # @param threshold [Float] fraction below baseline that counts as a regression (default 0.10 = 10%)
  # @param path [String] path to the baseline JSON file
  # @return [Boolean] true if no regressions found
  def self.compare_baseline(suite, label, threshold: 0.10,
    path: File.join(BENCH_ROOT, "benchmarks", "results", "baseline.json"))
    require "json"
    return true unless File.exist?(path)

    baseline = JSON.parse(File.read(path))
    section = baseline[label]
    return true unless section

    regressions = []
    suite.entries.each do |entry|
      baseline_entry = section[entry.label]
      next unless baseline_entry

      baseline_ips = baseline_entry["ips"].to_f
      next if baseline_ips.zero?

      current_ips = entry.stats.central_tendency
      ratio = current_ips / baseline_ips
      if ratio < (1 - threshold)
        regressions << format("  %-55s  %.1fx slower  (%.0f vs %.0f ips)",
          entry.label, 1.0 / ratio, current_ips, baseline_ips)
      end
    end

    if regressions.any?
      puts
      puts "⚠️  REGRESSIONS DETECTED (>#{(threshold * 100).to_i}% slowdown):"
      regressions.each { |r| puts r }
      puts
      false
    else
      true
    end
  end
end

# Pre-generate fixtures on first require
BenchmarkFixtures.generate_all
