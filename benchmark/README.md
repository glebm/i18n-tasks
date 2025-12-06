# i18n-tasks Performance Benchmarks

This directory contains performance testing scripts for i18n-tasks.

## Benchmark Data

By default, benchmarks use the i18n-tasks codebase itself (the `lib/` directory). This provides a real-world dataset but is relatively small.

For more comprehensive testing, generate fixture data:

```bash
# Generate fixtures (500 files, ~15000 keys)
ruby benchmark/generate_fixtures.rb

# Run benchmark with fixtures (cd into fixtures directory first)
cd benchmark/fixtures
ruby ../../benchmark/benchmark.rb
cd ../..
```

The fixtures include:

- Ruby models and controllers
- ERB, HAML, and Slim templates
- JavaScript, Vue, and JSX/React components

## Usage

```bash
# Run benchmark on actual codebase
ruby benchmark/benchmark.rb

# Run benchmark on fixtures
cd benchmark/fixtures
ruby ../../benchmark/benchmark.rb
cd ../..

# Quick test (minimal output)
ruby benchmark/quick_test.rb
```

## Benchmark Output

The `benchmark.rb` script runs comprehensive performance tests:

1. **Basic Performance**: Execution time, keys found, and node counts
2. **Parser vs Prism**: Comparison between AST parser and Prism parser
   - Default Parser (whitequark/parser)
   - Prism in rails mode
   - Prism in ruby mode
   - Speed differences and key count discrepancies
3. **Scanner Comparison**: Individual scanner performance and parallel vs sequential execution
4. **Cache Impact**: Performance with and without caching
5. **File Operations**: File discovery performance
6. **Iterations Per Second**: Throughput benchmark (requires benchmark-ips gem)
7. **Memory Usage**: Memory allocation analysis (requires benchmark-memory gem)

## Interpreting Results

- **Time**: Wall-clock time for execution (seconds)
- **Keys found**: Number of translation keys detected
- **Total nodes**: Number of nodes in the result tree

## Tips

- Run benchmarks multiple times for consistency
- Use fixtures for larger-scale performance testing
- Compare Parser vs Prism results when making parser changes
- Check for key count differences between parsers
