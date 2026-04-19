# frozen_string_literal: true

# End-to-end benchmarks for the full i18n-tasks pipeline.
#
# These measure the complete workflows that users actually run:
#   - missing_keys: find translations present in base locale but missing elsewhere
#   - unused_keys:  find keys defined in locale files but not used in source
#   - used_tree:    scan all source files and build the usage tree
#
# These are the most important benchmarks for catching regressions — any change
# to the scanner, data layer, or tree operations will show up here.
#
# Usage:
#   bundle exec ruby benchmarks/end_to_end_bench.rb
#   bundle exec ruby benchmarks/end_to_end_bench.rb --save    # save as new baseline
#   bundle exec ruby benchmarks/end_to_end_bench.rb --compare # compare against baseline

require_relative "bench_helper"

SAVE_RESULTS = ARGV.include?("--save")
COMPARE_RESULTS = ARGV.include?("--compare")

all_suites = []

# ---------------------------------------------------------------------------
# Benchmark each pipeline operation across all scales
# ---------------------------------------------------------------------------

[:small, :medium, :large].each do |scale|
  dir = BenchmarkFixtures.generate(scale)

  BenchHelper.header("End-to-end pipeline — #{scale} fixture")

  suite = Benchmark.ips do |x|
    x.config(warmup: 2, time: 15)

    x.report("used_tree     (#{scale})") do
      Dir.chdir(dir) do
        task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
        task.used_tree
      end
    end

    x.report("missing_keys  (#{scale})") do
      Dir.chdir(dir) do
        task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
        task.missing_keys
      end
    end

    x.report("unused_keys   (#{scale})") do
      Dir.chdir(dir) do
        task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
        task.unused_keys
      end
    end

    x.compare!
  end

  all_suites << [suite, "end_to_end/#{scale}"]
end

# ---------------------------------------------------------------------------
# Scanner backend comparison: parser AST vs Prism on medium fixture
# ---------------------------------------------------------------------------

BenchHelper.header("Scanner backend: parser AST vs Prism (medium used_tree)")

dir = BenchmarkFixtures.generate(:medium)

backend_suite = Benchmark.ips do |x|
  x.config(warmup: 2, time: 15)

  x.report("used_tree — parser AST (medium)") do
    Dir.chdir(dir) do
      task = I18n::Tasks::BaseTask.new(
        config_file: File.join(dir, "config", "i18n-tasks.yml"),
        search: {scanners: [["::I18n::Tasks::Scanners::RubyScanner", {only: %w[*.rb], prism: nil}],
          ["::I18n::Tasks::Scanners::ErbAstScanner", {only: %w[*.erb]}]]}
      )
      task.used_tree
    end
  end

  x.report("used_tree — prism (medium)") do
    Dir.chdir(dir) do
      task = I18n::Tasks::BaseTask.new(
        config_file: File.join(dir, "config", "i18n-tasks.yml"),
        search: {scanners: [["::I18n::Tasks::Scanners::RubyScanner", {only: %w[*.rb], prism: "rails"}],
          ["::I18n::Tasks::Scanners::ErbAstScanner", {only: %w[*.erb]}]]}
      )
      task.used_tree
    end
  end

  x.compare!
end

all_suites << [backend_suite, "end_to_end/backend_comparison"]

# ---------------------------------------------------------------------------
# Memory profiling on the most realistic scale (medium)
# ---------------------------------------------------------------------------

BenchHelper.header("Memory profile — missing_keys (medium)")
dir = BenchmarkFixtures.generate(:medium)
MemoryProfiler.report do
  Dir.chdir(dir) do
    task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
    task.missing_keys
  end
end.pretty_print(scale_bytes: true, detailed_report: false)

BenchHelper.header("Memory profile — unused_keys (medium)")
MemoryProfiler.report do
  Dir.chdir(dir) do
    task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
    task.unused_keys
  end
end.pretty_print(scale_bytes: true, detailed_report: false)

# ---------------------------------------------------------------------------
# Save / compare results
# ---------------------------------------------------------------------------

all_suites.each do |(suite, label)|
  BenchHelper.save_results(suite, label) if SAVE_RESULTS
  BenchHelper.compare_baseline(suite, label) if COMPARE_RESULTS
end
