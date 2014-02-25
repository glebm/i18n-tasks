require 'i18n/tasks/scanners/pattern_scanner'

module I18n::Tasks::Scanners
  # Scans for I18n.t(key, scope: ...) usages
  # both scope: "literal", and scope: [:array, :of, 'literals'] forms are supported
  # Caveat: scope is only detected when it is the first argument
  class PatternWithScopeScanner < PatternScanner
    protected

    # Given
    # @param [MatchData] match
    # @param [String] path
    # @return [String] full absolute key name with scope resolved if any
    def extract_key_from_match(match, path)
      key   = super
      scope = match[1]
      if scope
        scope_ns = scope.gsub(/[\[\]\s]+/, '').split(',').map { |arg| strip_literal_or_expr(arg) } * '.'
        "#{scope_ns}.#{key}"
      else
        key
      end
    end

    def default_pattern
      /#{super} (?# Up to key)
        (?:\s*,\s*#{scope_arg_re})?
      /x
    end

    def scope_arg
      'scope'
    end

    def literal_or_expr_re
      /(?:
       #{literal_re} |
       [\w():"'\s]+       (?# parse simple exprssions without ,)
      )/x
    end

    def strip_literal_or_expr(val)
      if val =~ /\A\w/
        "\#{#{val}}"
      else
        strip_literal(val)
      end
    end

    def array_or_literal_re(opts = {})
      el = opts[:expr] ? literal_or_expr_re : literal_re
      /#{el} |
       \[\s* ((?:#{el}\s*,\s*)*#{el}) \s*\]/x
    end

    def scope_arg_re
      /(?:
         :#{scope_arg}\s*=>\s* | (?# :scope => :home )
         #{scope_arg}:\s*        (?#    scope: :home )
        ) (#{array_or_literal_re expr: true})/x
    end

  end
end
