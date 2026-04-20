# frozen_string_literal: true

# Benchmarks for the source-code scanning hot path.
#
# Measures per-scanner throughput (IPS) for Ruby (parser AST and Prism backends)
# and ERB scanning across fixture scales.
#
# Usage:
#   bundle exec ruby benchmarks/scanning_bench.rb
#   bundle exec ruby benchmarks/scanning_bench.rb --save    # save as new baseline
#   bundle exec ruby benchmarks/scanning_bench.rb --compare # compare against baseline
#   bundle exec ruby benchmarks/scanning_bench.rb --memory  # include memory profiles

require_relative "bench_helper"

require "i18n/tasks/scanners/ruby_scanner"
require "i18n/tasks/scanners/erb_ast_scanner"
require "i18n/tasks/scanners/pattern_with_scope_scanner"
require "i18n/tasks/scanners/files/caching_file_finder_provider"
require "i18n/tasks/scanners/files/caching_file_reader"

SAVE_RESULTS = ARGV.include?("--save")
COMPARE_RESULTS = ARGV.include?("--compare")
MEMORY_PROFILE = ARGV.include?("--memory")

def build_scanner(scanner_class, app_dir, only_pattern:, shared_provider:, shared_reader:, **extra_config)
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
    file_finder_provider: shared_provider,
    file_reader: shared_reader
  )
end

all_suites = []

[:small, :medium].each do |scale|
  dir = BenchmarkFixtures.generate(scale)
  app_dir = File.join(dir, "app")

  BenchHelper.header("Scanning — #{scale} fixture")

  # Build shared provider/reader and warm their caches so the timed block
  # measures only parse throughput, not file-system traversal or I/O.
  shared_provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
  shared_reader = I18n::Tasks::Scanners::Files::CachingFileReader.new
  build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
    only_pattern: ["*.rb"], shared_provider: shared_provider,
    shared_reader: shared_reader, prism: nil).keys

  suite = Benchmark.ips do |x|
    x.config(warmup: 3, time: 10)

    x.report("RubyScanner/parser (#{scale})") do
      build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
        only_pattern: ["*.rb"], shared_provider: shared_provider,
        shared_reader: shared_reader, prism: nil).keys
    end

    x.report("RubyScanner/prism  (#{scale})") do
      build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
        only_pattern: ["*.rb"], shared_provider: shared_provider,
        shared_reader: shared_reader, prism: "rails").keys
    end

    x.report("ErbAstScanner      (#{scale})") do
      build_scanner(I18n::Tasks::Scanners::ErbAstScanner, app_dir,
        only_pattern: ["*.erb"], shared_provider: shared_provider,
        shared_reader: shared_reader).keys
    end

    x.report("PatternScanner     (#{scale})") do
      build_scanner(I18n::Tasks::Scanners::PatternWithScopeScanner, app_dir,
        only_pattern: ["*.rb", "*.erb"], shared_provider: shared_provider,
        shared_reader: shared_reader).keys
    end

    x.compare!
  end

  all_suites << [suite, "scanning/#{scale}"]
end

if MEMORY_PROFILE
  dir = BenchmarkFixtures.generate(:medium)
  app_dir = File.join(dir, "app")
  shared_provider = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new
  shared_reader = I18n::Tasks::Scanners::Files::CachingFileReader.new
  # Warm caches so memory report reflects only parse allocations
  build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
    only_pattern: ["*.rb"], shared_provider: shared_provider,
    shared_reader: shared_reader, prism: nil).keys

  BenchHelper.header("Memory profile — RubyScanner/parser (medium)")
  MemoryProfiler.report do
    build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
      only_pattern: ["*.rb"], shared_provider: shared_provider,
      shared_reader: shared_reader, prism: nil).keys
  end.pretty_print(scale_bytes: true, detailed_report: false)

  BenchHelper.header("Memory profile — RubyScanner/prism (medium)")
  MemoryProfiler.report do
    build_scanner(I18n::Tasks::Scanners::RubyScanner, app_dir,
      only_pattern: ["*.rb"], shared_provider: shared_provider,
      shared_reader: shared_reader, prism: "rails").keys
  end.pretty_print(scale_bytes: true, detailed_report: false)
end

passed = true
all_suites.each do |(suite, label)|
  BenchHelper.save_results(suite, label) if SAVE_RESULTS
  passed = false if COMPARE_RESULTS && !BenchHelper.compare_baseline(suite, label)
end

exit(1) if COMPARE_RESULTS && !passed
