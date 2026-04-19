# frozen_string_literal: true

# Micro-benchmarks for the tree data structure operations.
#
# These isolate pure tree performance with no I/O, making them useful for
# detecting regressions in the tree algorithms themselves.
#
# Usage:
#   bundle exec ruby benchmarks/tree_bench.rb
#   bundle exec ruby benchmarks/tree_bench.rb --save
#   bundle exec ruby benchmarks/tree_bench.rb --compare

require_relative "bench_helper"

require "i18n/tasks/data/tree/siblings"
require "i18n/tasks/data/tree/node"

SAVE_RESULTS = ARGV.include?("--save")
COMPARE_RESULTS = ARGV.include?("--compare")

Node = I18n::Tasks::Data::Tree::Node
Siblings = I18n::Tasks::Data::Tree::Siblings

# ---------------------------------------------------------------------------
# Helpers to build in-memory trees of various sizes without touching disk
# ---------------------------------------------------------------------------

def flat_keys(count)
  sections = %w[users posts comments orders products admin auth errors shared mailers]
  keys = []
  sections.cycle do |s|
    break if keys.size >= count

    10.times do |i|
      break if keys.size >= count

      keys << "#{s}.section_#{i / 5}.item_#{i}.label"
    end
  end
  keys.first(count)
end

def build_siblings(key_count)
  Siblings.from_key_names(flat_keys(key_count))
end

def build_nested_hash(key_count, locale = "en")
  keys = flat_keys(key_count)
  hash = {locale => {}}
  keys.each_with_index do |key, i|
    parts = key.split(".")
    node = hash[locale]
    parts[0..-2].each { |p|
      node[p] ||= {}
      node = node[p]
    }
    node[parts.last] = "value_#{i}"
  end
  hash
end

# Pre-build fixtures so allocation is not counted
SMALL_KEYS = flat_keys(200).freeze
MEDIUM_KEYS = flat_keys(2_000).freeze
LARGE_KEYS = flat_keys(8_000).freeze

SMALL_HASH = build_nested_hash(200).freeze
MEDIUM_HASH = build_nested_hash(2_000).freeze

SMALL_TREE = build_siblings(200).freeze
MEDIUM_TREE = build_siblings(2_000).freeze
LARGE_TREE = build_siblings(8_000).freeze

SMALL_TREE_B = build_siblings(200).freeze
MEDIUM_TREE_B = build_siblings(2_000).freeze

# ---------------------------------------------------------------------------
# Construction benchmarks
# ---------------------------------------------------------------------------

BenchHelper.header("Tree construction")

construction_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("from_key_names (200 keys)") do
    Siblings.from_key_names(SMALL_KEYS)
  end

  x.report("from_key_names (2k keys)") do
    Siblings.from_key_names(MEDIUM_KEYS)
  end

  x.report("from_key_names (8k keys)") do
    Siblings.from_key_names(LARGE_KEYS)
  end

  x.report("from_nested_hash (200 keys)") do
    Siblings.from_nested_hash(SMALL_HASH)
  end

  x.report("from_nested_hash (2k keys)") do
    Siblings.from_nested_hash(MEDIUM_HASH)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Merge benchmarks
# ---------------------------------------------------------------------------

BenchHelper.header("Tree merge")

merge_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("merge! (200 into 200 keys)") do
    SMALL_TREE.derive.merge!(SMALL_TREE_B)
  end

  x.report("merge! (2k into 2k keys)") do
    MEDIUM_TREE.derive.merge!(MEDIUM_TREE_B)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Traversal benchmarks
# ---------------------------------------------------------------------------

BenchHelper.header("Tree traversal")

traversal_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("leaves (2k keys)") do
    MEDIUM_TREE.leaves.to_a
  end

  x.report("key_names (2k keys)") do
    MEDIUM_TREE.key_names
  end

  x.report("key_names (8k keys)") do
    LARGE_TREE.key_names
  end

  x.report("select_keys (2k, match half)") do
    i = 0
    MEDIUM_TREE.select_keys { |_key, _node| (i += 1).odd? }
  end

  x.report("nodes block iteration (2k keys)") do
    MEDIUM_TREE.nodes.to_a
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# subtract_by_key! benchmark
# ---------------------------------------------------------------------------

BenchHelper.header("Tree subtract")

subtract_suite = Benchmark.ips do |x|
  x.config(warmup: 3, time: 10)

  x.report("subtract_by_key! (200 keys)") do
    SMALL_TREE.derive.subtract_by_key!(SMALL_TREE_B)
  end

  x.report("subtract_by_key! (2k keys)") do
    MEDIUM_TREE.derive.subtract_by_key!(MEDIUM_TREE_B)
  end

  x.compare!
end

# ---------------------------------------------------------------------------
# Memory profiles
# ---------------------------------------------------------------------------

BenchHelper.header("Memory — from_key_names (2k keys)")
MemoryProfiler.report { Siblings.from_key_names(MEDIUM_KEYS) }
  .pretty_print(scale_bytes: true, detailed_report: false)

BenchHelper.header("Memory — from_nested_hash (2k keys)")
MemoryProfiler.report { Siblings.from_nested_hash(MEDIUM_HASH) }
  .pretty_print(scale_bytes: true, detailed_report: false)

if SAVE_RESULTS
  BenchHelper.save_results(construction_suite, "tree/construction")
  BenchHelper.save_results(merge_suite, "tree/merge")
  BenchHelper.save_results(traversal_suite, "tree/traversal")
  BenchHelper.save_results(subtract_suite, "tree/subtract")
end

if COMPARE_RESULTS
  BenchHelper.compare_baseline(construction_suite, "tree/construction")
  BenchHelper.compare_baseline(merge_suite, "tree/merge")
  BenchHelper.compare_baseline(traversal_suite, "tree/traversal")
  BenchHelper.compare_baseline(subtract_suite, "tree/subtract")
end
