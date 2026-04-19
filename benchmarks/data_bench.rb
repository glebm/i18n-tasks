# frozen_string_literal: true

# Benchmarks for YAML data loading and writing (the I/O layer).
#
# Measures the cost of:
# - Parsing YAML locale files into Ruby hashes
# - Dumping Ruby hashes back to YAML strings
# - Building Siblings trees from parsed YAML hashes
# - The full data[locale] load path used by BaseTask
#
# Usage:
#   bundle exec ruby benchmarks/data_bench.rb
#   bundle exec ruby benchmarks/data_bench.rb --save
#   bundle exec ruby benchmarks/data_bench.rb --compare

require_relative "bench_helper"

require "yaml"
require "i18n/tasks/data/adapter/yaml_adapter"
require "i18n/tasks/data/tree/siblings"

SAVE_RESULTS = ARGV.include?("--save")
COMPARE_RESULTS = ARGV.include?("--compare")

Siblings = I18n::Tasks::Data::Tree::Siblings
YamlAdapter = I18n::Tasks::Data::Adapter::YamlAdapter

# Build YAML strings of various sizes in memory (no disk I/O during benchmarks)
def yaml_string_for_scale(scale)
  dir = BenchmarkFixtures.generate(scale)
  File.read(File.join(dir, "config", "locales", "en.yml"))
end

SMALL_YAML = yaml_string_for_scale(:small).freeze
MEDIUM_YAML = yaml_string_for_scale(:medium).freeze
LARGE_YAML = yaml_string_for_scale(:large).freeze

SMALL_HASH = YamlAdapter.parse(SMALL_YAML, nil).freeze
MEDIUM_HASH = YamlAdapter.parse(MEDIUM_YAML, nil).freeze
LARGE_HASH = YamlAdapter.parse(LARGE_YAML, nil).freeze

SMALL_TREE = Siblings.from_nested_hash(SMALL_HASH).freeze
MEDIUM_TREE = Siblings.from_nested_hash(MEDIUM_HASH).freeze

# ---------------------------------------------------------------------------
# YAML parse benchmarks
# ---------------------------------------------------------------------------

BenchHelper.header("YAML parse (string → hash)")

parse_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("YAML parse small  (~#{SMALL_YAML.size / 1024}KB)") do
    YamlAdapter.parse(SMALL_YAML, nil)
  end

  x.report("YAML parse medium (~#{MEDIUM_YAML.size / 1024}KB)") do
    YamlAdapter.parse(MEDIUM_YAML, nil)
  end

  x.report("YAML parse large  (~#{LARGE_YAML.size / 1024}KB)") do
    YamlAdapter.parse(LARGE_YAML, nil)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# YAML dump benchmarks
# ---------------------------------------------------------------------------

BenchHelper.header("YAML dump (hash → string)")

dump_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("YAML dump small  tree") do
    YamlAdapter.dump(SMALL_HASH, nil)
  end

  x.report("YAML dump medium tree") do
    YamlAdapter.dump(MEDIUM_HASH, nil)
  end

  x.report("YAML dump large  tree") do
    YamlAdapter.dump(LARGE_HASH, nil)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Hash → Siblings tree construction
# ---------------------------------------------------------------------------

BenchHelper.header("Hash → Siblings tree construction")

load_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("from_nested_hash small") do
    Siblings.from_nested_hash(SMALL_HASH)
  end

  x.report("from_nested_hash medium") do
    Siblings.from_nested_hash(MEDIUM_HASH)
  end

  x.report("from_nested_hash large") do
    Siblings.from_nested_hash(LARGE_HASH)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Full data load via BaseTask
# ---------------------------------------------------------------------------

BenchHelper.header("Full data[locale] load via BaseTask")

data_load_suite = Benchmark.ips do |x|
  x.config(warmup: 2, time: 10)

  [:small, :medium].each do |scale|
    dir = BenchmarkFixtures.generate(scale)

    x.report("data['en'] load (#{scale})") do
      Dir.chdir(dir) do
        task = I18n::Tasks::BaseTask.new(config_file: File.join(dir, "config", "i18n-tasks.yml"))
        task.data["en"]
      end
    end
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Memory profiles
# ---------------------------------------------------------------------------

BenchHelper.header("Memory — YAML parse + tree build (medium)")
MemoryProfiler.report do
  hash = YamlAdapter.parse(MEDIUM_YAML, nil)
  Siblings.from_nested_hash(hash)
end.pretty_print(scale_bytes: true, detailed_report: false)

BenchHelper.header("Memory — YAML dump (medium)")
MemoryProfiler.report { YamlAdapter.dump(MEDIUM_HASH, nil) }
  .pretty_print(scale_bytes: true, detailed_report: false)

if SAVE_RESULTS
  BenchHelper.save_results(parse_suite, "data/yaml_parse")
  BenchHelper.save_results(dump_suite, "data/yaml_dump")
  BenchHelper.save_results(load_suite, "data/tree_load")
  BenchHelper.save_results(data_load_suite, "data/full_load")
end

if COMPARE_RESULTS
  BenchHelper.compare_baseline(parse_suite, "data/yaml_parse")
  BenchHelper.compare_baseline(dump_suite, "data/yaml_dump")
  BenchHelper.compare_baseline(load_suite, "data/tree_load")
  BenchHelper.compare_baseline(data_load_suite, "data/full_load")
end
