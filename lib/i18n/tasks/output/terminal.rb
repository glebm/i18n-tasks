# coding: utf-8
module I18n
  module Tasks
    module Output
      class Terminal
        include Term::ANSIColor

        def missing(missing)
          print_title "Missing keys and translations (#{missing.length})"
          if missing.present?
            $stderr.puts "#{bold 'Legend:'} #{red '✗'} key missing, #{yellow bold '∅'} translation blank, #{blue bold '='} value equal to base locale, #{cyan 'value in base locale'}"
            key_col_width = missing.map { |x| x[:key] }.max_by(&:length).length + 2
            missing.each { |m| print_missing_translation m, key_col_width: key_col_width }
          else
            print_success 'Good job! No translations missing!'
          end
        end

        def unused(unused)
          print_title "Unused i18n keys (#{unused.length})"
          if unused.present?
            key_col_width = unused.max_by { |x| x[0].length }[0].length + 2
            unused.each { |(key, value)| puts "#{magenta key.ljust(key_col_width)}#{cyan value.to_s.strip}" }
          else
            print_success 'Good job! Every translation is used!'
          end
        end

        private

        extend Term::ANSIColor

        def print_title(title)
          $stderr.puts "#{bold cyan title.strip} #{dark "|"} #{bold "i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          $stderr.puts(bold green message)
        end

        STATUS_TEXTS = {
            none:    red("✗".ljust(6)),
            blank:   yellow(bold '∅'.ljust(6)),
            eq_base: blue(bold "=".ljust(6))
        }

        def print_missing_translation(m, opts)
          locale, key, base_value, status_text = m[:locale], m[:key], m[:base_value].to_s.try(:strip), " #{STATUS_TEXTS[m[:type]]}"

          key = magenta "#{key}".ljust(opts[:key_col_width])
          s   = if m[:type] == :none
                  "#{red bold locale.ljust(4)} #{status_text} #{key}"
                else
                  "#{bold locale.ljust(4)} #{status_text} #{key} #{cyan base_value.strip.gsub("\n", ' ')}"
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
