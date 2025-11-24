#!/usr/bin/env ruby
# frozen_string_literal: true

# i18n-tasks Performance Benchmark Suite
# Usage: ruby benchmark/benchmark.rb

require "bundler/setup"
require "benchmark"
require_relative "../lib/i18n/tasks"

begin
  require "benchmark/ips"
rescue LoadError
  # benchmark-ips not available
end

begin
  require "benchmark/memory"
rescue LoadError
  # benchmark-memory not available
end

class I18nTasksBenchmark
  attr_reader :task

  def initialize
    @task = I18n::Tasks::BaseTask.new

    # Check if we're in fixtures directory
    if Dir.pwd.end_with?("benchmark/fixtures")
      puts "Using benchmark fixtures"
    else
      puts "Using actual i18n-tasks codebase"
    end

    puts "\ni18n-tasks Performance Benchmark Suite"
    puts "=" * 70
    puts "Configuration:"
    puts "  Search paths: #{task.config[:search][:paths].join(", ")}"
    puts "  Scanners: #{task.config[:search][:scanners]&.size}"
    puts "=" * 70
  end

  def run_all
    benchmark_basic_performance
    benchmark_parser_vs_prism
    benchmark_scanner_comparison
    benchmark_cache_impact
    benchmark_file_operations
    benchmark_ips
    benchmark_memory_usage

    puts "\n" + "=" * 70
    puts "Benchmark complete!"
    puts "=" * 70
  end

  private

  def benchmark_basic_performance
    puts "\n1. Basic used_tree Performance"
    puts "-" * 70

    result = nil
    time = Benchmark.measure do
      result = task.used_tree
    end

    puts "  Time: #{time.real.round(3)}s"
    puts "  Keys found: #{result.key_names.size}"
    puts "  Total nodes: #{result.nodes.size}"
    puts "  Leaf nodes: #{result.leaves.count}"
  end

  def benchmark_parser_vs_prism
    puts "\n2. Parser vs Prism Comparison"
    puts "-" * 70

    # Save original config
    orig_config = task.config[:search].dup
    results = {}

    # Test with Parser (default)
    puts "  Running Parser (default AST)..."
    task.config[:search] = orig_config.merge(prism: nil)
    clear_cache
    parser_result = nil
    parser_time = Benchmark.measure do
      parser_result = task.used_tree
    end
    results[:parser] = {
      time: parser_time.real,
      keys: parser_result.key_names.size,
      nodes: parser_result.nodes.size
    }

    # Test with Prism (rails mode)
    puts "  Running Prism rails mode..."
    task.config[:search] = orig_config.merge(prism: "rails")
    clear_cache
    prism_rails_result = nil
    prism_rails_time = Benchmark.measure do
      prism_rails_result = task.used_tree
    end
    results[:prism_rails] = {
      time: prism_rails_time.real,
      keys: prism_rails_result.key_names.size,
      nodes: prism_rails_result.nodes.size
    }

    # Test with Prism (ruby mode)
    puts "  Running Prism ruby mode..."
    task.config[:search] = orig_config.merge(prism: "ruby")
    clear_cache
    prism_ruby_result = nil
    prism_ruby_time = Benchmark.measure do
      prism_ruby_result = task.used_tree
    end
    results[:prism_ruby] = {
      time: prism_ruby_time.real,
      keys: prism_ruby_result.key_names.size,
      nodes: prism_ruby_result.nodes.size
    }

    # Display comparison
    display_parser_comparison(results)

    # Restore original config
    task.config[:search] = orig_config
    clear_cache
  end

  def benchmark_scanner_comparison
    puts "\n3. Scanner Performance"
    puts "-" * 70

    config = task.search_config

    # Individual scanners
    puts "  Individual Scanners:"
    scanners = config[:scanners].map do |(class_name, args)|
      scanner_class = Object.const_get(class_name)
      opts = config.merge(args || {})
      scanner_class.new(config: opts)
    end

    scanners.each_with_index do |scanner, i|
      result = nil
      time = Benchmark.measure do
        result = scanner.keys
      end
      puts "    #{scanner.class.name.split("::").last}: #{time.real.round(3)}s (#{result.size} keys)"
    end

    puts

    # Parallel vs Sequential
    puts "  Execution Mode Comparison:"

    # Parallel
    parallel_time = Benchmark.measure do
      task.scanner(strict: true).keys
    end
    puts "    Parallel: #{parallel_time.real.round(3)}s"

    # Sequential
    sequential_time = Benchmark.measure do
      all_keys = []
      config[:scanners].each do |(class_name, args)|
        scanner_class = Object.const_get(class_name)
        opts = config.merge(args || {})
        opts[:strict] = true
        scanner = scanner_class.new(config: opts)
        all_keys.concat(scanner.keys)
      end
      I18n::Tasks::Scanners::Results::KeyOccurrences.merge_keys(all_keys)
    end
    puts "    Sequential: #{sequential_time.real.round(3)}s"

    speedup = sequential_time.real / parallel_time.real
    puts "    Speedup: #{speedup.round(2)}x"
  end

  def benchmark_cache_impact
    puts "\n4. Cache Impact"
    puts "-" * 70

    # First run (no cache)
    clear_cache
    first_run_time = Benchmark.measure do
      task.used_tree
    end

    # Second run (with cache)
    second_run_time = Benchmark.measure do
      task.used_tree
    end

    puts "  First run (no cache): #{first_run_time.real.round(3)}s"
    puts "  Second run (cached): #{second_run_time.real.round(3)}s"
    puts "  Speedup: #{(first_run_time.real / second_run_time.real).round(2)}x"
  end

  def benchmark_file_operations
    puts "\n5. File Operations"
    puts "-" * 70

    config = task.search_config
    file_count = 0
    find_time = Benchmark.measure do
      file_finder = I18n::Tasks::Scanners::Files::CachingFileFinderProvider.new(
        exclude: config[:exclude]
      ).get
      file_count = file_finder.find_files.size
    end

    puts "  File discovery: #{find_time.real.round(3)}s"
    puts "  Files found: #{file_count}"
  end

  def benchmark_ips
    puts "\n6. Iterations Per Second (IPS)"
    puts "-" * 70

    unless defined?(Benchmark::IPS)
      puts "  Skipped (gem install benchmark-ips to enable)"
      return
    end

    puts "  Running throughput benchmark..."
    puts

    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report("used_tree (no cache)") do
        clear_cache
        task.used_tree
      end

      x.report("used_tree (cached)") do
        task.used_tree
      end

      x.compare!
    end
  end

  def benchmark_memory_usage
    puts "\n7. Memory Usage"
    puts "-" * 70

    unless defined?(Benchmark::Memory)
      puts "  Skipped (gem install benchmark-memory to enable)"
      return
    end

    Benchmark.memory do |x|
      x.report("used_tree") do
        clear_cache
        task.used_tree
      end

      x.report("scanner only") do
        clear_cache
        task.scanner(strict: true).keys
      end

      x.compare!
    end
  end

  def display_parser_comparison(results)
    puts
    puts "  Parser (default AST):"
    puts "    Time: #{results[:parser][:time].round(3)}s"
    puts "    Keys: #{results[:parser][:keys]}"
    puts "    Nodes: #{results[:parser][:nodes]}"
    puts

    puts "  Prism (rails mode):"
    puts "    Time: #{results[:prism_rails][:time].round(3)}s"
    puts "    Keys: #{results[:prism_rails][:keys]}"
    puts "    Nodes: #{results[:prism_rails][:nodes]}"
    speedup = results[:parser][:time] / results[:prism_rails][:time]
    puts "    vs Parser: #{(speedup > 1) ? (speedup.round(2).to_s + "x faster") : ((1 / speedup).round(2).to_s + "x slower")}"
    if results[:prism_rails][:keys] != results[:parser][:keys]
      puts "    ⚠️  Key count differs by #{(results[:prism_rails][:keys] - results[:parser][:keys]).abs}"
    end
    puts

    puts "  Prism (ruby mode):"
    puts "    Time: #{results[:prism_ruby][:time].round(3)}s"
    puts "    Keys: #{results[:prism_ruby][:keys]}"
    puts "    Nodes: #{results[:prism_ruby][:nodes]}"
    speedup = results[:parser][:time] / results[:prism_ruby][:time]
    puts "    vs Parser: #{(speedup > 1) ? (speedup.round(2).to_s + "x faster") : ((1 / speedup).round(2).to_s + "x slower")}"
    if results[:prism_ruby][:keys] != results[:parser][:keys]
      puts "    ⚠️  Key count differs by #{(results[:prism_ruby][:keys] - results[:parser][:keys]).abs}"
    end
  end

  def clear_cache
    task.instance_variable_set(:@keys_used_in_source_tree, nil)
    task.instance_variable_set(:@scanner, nil)
  end
end

if __FILE__ == $PROGRAM_NAME
  benchmark = I18nTasksBenchmark.new
  benchmark.run_all
end
