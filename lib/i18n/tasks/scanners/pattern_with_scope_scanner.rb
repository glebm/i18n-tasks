require 'i18n/tasks/scanners/pattern_scanner'

module I18n::Tasks::Scanners
  # Scans for I18n.t(key, scope: ...) usages
  # both scope: "literal", and scope: [:array, :of, 'literals'] forms are supported
  # Caveat: scope is only detected when it is the first argument
  class PatternWithScopeScanner < PatternScanner

    def default_pattern
      # capture the first argument and scope argument if present
      /#{super}
      (?: \s*,\s* #{scope_arg_re} )? (?# capture scope in second argument )
      /x
    end

    protected

    # Given
    # @param [MatchData] match
    # @param [String] path
    # @return [String] full absolute key name with scope resolved if any
    def match_to_key(match, path)
      key   = super
      scope = match[1]
      if scope
        scope_ns = scope.gsub(/[\[\]\s]+/, '').split(',').map { |arg| strip_literal(arg) } * '.'
        "#{scope_ns}.#{key}"
      else
        key unless match[0] =~ /\A\w/
      end
    end


    # also parse expressions with literals
    def literal_re
      /(?: (?: #{super} ) | #{expr_re} )/x
    end

    # strip literals, convert expressions to #{interpolations}
    def strip_literal(val)
      if val =~ /\A\w/
        "\#{#{val}}"
      else
        super(val)
      end
    end

    # Regexps:

    # scope: literal or code expression or an array of these
    def scope_arg_re
      /(?:
         :#{scope_arg_name}\s*=>\s* | (?# :scope => :home )
         #{scope_arg_name}:\s*        (?#    scope: :home )
        ) (#{array_or_one_literal_re})/x
    end

    def scope_arg_name
      'scope'
    end

    # match code expression
    # matches characters until , as a heuristic to parse scopes like [:categories, cat.key]
    # can be massively improved by matching parenthesis
    def expr_re
      /[\w():"'.\s]+/x
    end

    # match +el+ or array of +el+
    def array_or_one_literal_re(el = literal_re)
      /#{el} |
       \[\s* (?:#{el}\s*,\s*)* #{el} \s*\]/x
    end
  end
end
