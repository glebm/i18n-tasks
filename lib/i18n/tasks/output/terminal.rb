# coding: utf-8
module I18n
  module Tasks
    module Output
      class Terminal
        include Term::ANSIColor

        def missing(missing)
          $stderr.puts bold cyan "Missing keys and translations (#{missing.length})"
          if missing.present?
            $stderr.puts "#{bold 'Legend:'} #{red '✗'} key missing, #{yellow bold '∅'} translation blank, #{blue bold '='} value equal to base locale; #{cyan 'value in base locale'}"
            key_col_width = missing.map { |x| x[:key] }.max_by(&:length).length + 2
            missing.each { |m| print_missing_translation m, key_col_width: key_col_width }
          else
            $stderr.puts(bold green 'Good job! No translations missing!')
          end
        end

        def unused(unused)
          $stderr.puts bold cyan("Unused i18n keys (#{unused.length})")
          if unused.present?
            key_col_width = unused.max_by { |x| x[0].length }[0].length + 2
            unused.each { |(key, value)| puts "#{magenta key.ljust(key_col_width)}#{cyan value.to_s.strip}" }
          else
            $stderr.puts(bold green 'Good job! Every translation is used!')
          end
        end

        private

        extend Term::ANSIColor
        STATUS_TEXTS = {
            none:    red("✗".ljust(6)),
            blank:   yellow(bold '∅'.ljust(6)),
            eq_base: blue(bold "=".ljust(6))
        }

        def print_missing_translation(m, opts)
          locale, key, base_value, status_text = m[:locale], m[:key], m[:base_value].to_s.try(:strip), " #{STATUS_TEXTS[m[:type]]}"

          long = base_value.length > 50

          key = magenta "#{key}#{':' if long}".ljust(opts[:key_col_width])
          base_value = "\n#{indent(base_value, 13)}\n" if long
          s   = if m[:type] == :none
                  "#{red bold locale.ljust(4)} #{status_text} #{key}"
                else
                  "#{bold locale.ljust(4)} #{status_text} #{key} #{cyan base_value}"
                end
          puts s
        end

        private
        def indent(txt, n = 2)
          spaces = ' ' * n
          txt.gsub /^/, spaces
        end
      end
    end
  end
end
