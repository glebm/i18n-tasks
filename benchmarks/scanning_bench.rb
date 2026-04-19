# frozen_string_literal: true

# Benchmarks for the source-code scanning hot path.
#
# Measures per-scanner throughput (IPS) for Ruby (parser AST and Prism backends)
# and ERB scanning across fixture scales.
#
# Usage:
#   bundle exec ruby benchmarks/scanning_bench.rb
#   bundle exec ruby benchmarks/scanning_bench.rb --save   # save as new baseline
#   bundle exec ruby benchmarks/scanning_bench.rb --compare # compare against baseline

require_relative "bench_helper"

require "i18n/tasks/scanners/ruby_scanner"
require "i18n/tasks/scanners/erb_ast_scanner"
require "i18n/tasks/scanners/pattern_with_scope_scanner"
require "i18n/tasks/scanners/files/caching_file_finder_provider"
require "i18n/tasks/scanners/files/caching_file_reader"

SAVE_RESULTS = ARGV.include?("--save")
COMPARE_RESULTS = ARGV.include?("--compare")

def build_scanner(scanner_class, fixture_dir, only_pattern:, **extra_config)
  app_dir = File.join(fixture_dir, "app")
  config = {
    paths: [app_dir],
    only: Array(only_pattern),
    exclude: [],
    relative_roots: [
      File.join(app_dir, "controllers"),
      File.join(app_dir, "helpers"),
      File.join(app_dir, "views")
    ],
    relative_exclude_method_name_paths: [],
    **extra_config
  }
  scanner_class.new(
    config: config,
    file_finder_provider: I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new,
    file_reader: I18n::Tasks::Scanners::Files::CachingFileReader.new
  )
end

all_suites = []

[:small, :medium].each do |scale|
  dir = BenchmarkFixtures.generate(scale)

  BenchHelper.header("Scanning — #{scale} fixture")

  suite = Benchmark.ips do |x|
    x.config(warmup: 3, time: 10)

    x.report("RubyScanner/parser (#{scale})") do
      build_scanner(
        I18n::Tasks::Scanners::RubyScanner,
        dir,
        only_pattern: ["*.rb"],
        prism: nil
      ).keys
    end

    x.report("RubyScanner/prism  (#{scale})") do
      build_scanner(
        I18n::Tasks::Scanners::RubyScanner,
        dir,
        only_pattern: ["*.rb"],
        prism: "rails"
      ).keys
    end

    x.report("ErbAstScanner      (#{scale})") do
      build_scanner(
        I18n::Tasks::Scanners::ErbAstScanner,
        dir,
        only_pattern: ["*.erb"]
      ).keys
    end

    x.report("PatternScanner     (#{scale})") do
      build_scanner(
        I18n::Tasks::Scanners::PatternWithScopeScanner,
        dir,
        only_pattern: ["*.rb", "*.erb"]
      ).keys
    end

    x.compare!
  end

  all_suites << [suite, "scanning/#{scale}"]
end

# Memory profile the full scanner suite on the medium fixture
BenchHelper.header("Memory profile — RubyScanner/parser (medium)")
dir = BenchmarkFixtures.generate(:medium)

report = MemoryProfiler.report do
  build_scanner(
    I18n::Tasks::Scanners::RubyScanner,
    dir,
    only_pattern: ["*.rb"],
    prism: nil
  ).keys
end
report.pretty_print(scale_bytes: true, detailed_report: false)

BenchHelper.header("Memory profile — RubyScanner/prism (medium)")
report = MemoryProfiler.report do
  build_scanner(
    I18n::Tasks::Scanners::RubyScanner,
    dir,
    only_pattern: ["*.rb"],
    prism: "rails"
  ).keys
end
report.pretty_print(scale_bytes: true, detailed_report: false)

all_suites.each do |(suite, label)|
  BenchHelper.save_results(suite, label) if SAVE_RESULTS
  BenchHelper.compare_baseline(suite, label) if COMPARE_RESULTS
end
