module I18n
  module Tasks
    class Key
      module MatchPattern
        def key_match_pattern
          @key_match_pattern ||= begin
            k = key
            "#{k.gsub(/\#{.*?}/, '*')}#{'*' if k.end_with?('.')}"
          end
        end

        # A key interpolated with expression
        def expr?
          if @is_expr.nil?
            k        = key
            @is_expr = (k =~ /\#{.*?}/ || k.end_with?('.'))
          end
          @is_expr
        end
      end
    end
  end
end
