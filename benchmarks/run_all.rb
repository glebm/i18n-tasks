#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs all benchmarks and optionally saves / compares against a baseline.
#
# Usage:
#   bundle exec ruby benchmarks/run_all.rb              # run everything
#   bundle exec ruby benchmarks/run_all.rb --save       # run + save as new baseline
#   bundle exec ruby benchmarks/run_all.rb --compare    # run + compare against baseline
#   bundle exec ruby benchmarks/run_all.rb --only=tree  # run only tree benchmarks
#
# The --only flag accepts comma-separated values: tree, data, scanning, e2e

bench_dir = File.dirname(__FILE__)

save = ARGV.include?("--save")
compare = ARGV.include?("--compare")

only_filter = ARGV.grep(/\A--only=/).first&.sub("--only=", "")&.split(",") || []

all_benches = {
  "scanning" => File.join(bench_dir, "scanning_bench.rb"),
  "tree" => File.join(bench_dir, "tree_bench.rb"),
  "data" => File.join(bench_dir, "data_bench.rb"),
  "e2e" => File.join(bench_dir, "end_to_end_bench.rb")
}

benches = if only_filter.any?
  all_benches.slice(*only_filter)
else
  all_benches
end

if benches.empty?
  warn "Unknown --only values. Available: #{all_benches.keys.join(", ")}"
  exit 1
end

flags = []
flags << "--save" if save
flags << "--compare" if compare

failed = false
benches.each do |name, path|
  puts
  puts "━" * 70
  puts "  Running: #{name}"
  puts "━" * 70

  result = system(RbConfig.ruby, path, *flags)
  failed = true unless result
end

exit(failed ? 1 : 0)
