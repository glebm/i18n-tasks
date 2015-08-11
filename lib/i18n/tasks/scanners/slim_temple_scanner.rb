require 'i18n/tasks/scanners/temple_scanner'

module I18n::Tasks::Scanners
  # Scan slim templates.
  # Work-in-progress.
  class SlimTempleScanner < TempleScanner

    def initialize(**args)
      super(gem_name: 'slim', suggested_gem_version: '~> 3.0', class_name: 'Slim::Parser',
            requires: %w(slim/parser slim/filter slim/embedded), **args)
    end

    protected

    def scan_file(path)
      parser     = parser_class.new(file: path)
      contents   = read_file(path)
      temple_ast = parser.call(contents)
      # todo: the bare parser is not enough, figure out the modules to use to get to the [:code, ...] IR.
      $stderr.puts temple_ast.inspect
      []
    end
  end
end
