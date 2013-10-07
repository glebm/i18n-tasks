module I18n
  module Tasks
    module Output
      class Terminal
        include Term::ANSIColor

        def missing(keys)
          $stderr.puts bold cyan "Missing keys and translations (#{keys.length})"
          $stderr.puts cyan <<-TEXT
        Legend: #{red '✗'} key missing, #{yellow bold '∅'} translation blank, #{yellow bold '='} value equal to base locale.
          TEXT
          keys.each { |m| print_missing_translation m }
        end

        def unused(keys)
          $stderr.puts bold cyan("Unused i18n keys (#{keys.length})")
          keys.each { |(key, value)| puts " #{magenta(key).ljust(60)}\t#{cyan value}" }
        end

        private

        extend Term::ANSIColor
        STATUS_TEXTS = {
            none:    red("✗".ljust(6)),
            blank:   yellow(bold '∅'.ljust(6)),
            eq_base: yellow(bold "=".ljust(6))
        }

        def print_missing_translation(m)
          locale, key, base_value, status_text = m[:locale], m[:key], m[:base_value], " #{STATUS_TEXTS[m[:type]]}"

          key = magenta(key).ljust(50)
          s   = if m[:type] == :none
                  "#{red bold(locale.ljust(5))} #{status_text} #{key}"
                else
                  " #{bold(locale.ljust(5))} #{status_text} #{key} #{cyan base_value}"
                end
          puts s
        end
      end
    end
  end
end
