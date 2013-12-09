# coding: utf-8
require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base
        include Term::ANSIColor

        def missing_translations(recs = task.untranslated_keys)
          print_title missing_title(recs)
          if recs.present?

            $stderr.puts "#{bold 'Types:'} #{missing_types.values.map { |t| "#{t[:glyph]} #{t[:summary]}" } * ', '}"

            print_table headings: [magenta(bold('Locale')), bold('Type'), magenta('i18n Key'), bold(cyan "Base value (#{base_locale})")] do |t|
              t.rows = recs.map { |rec|
                glyph = missing_types[rec[:type]][:glyph]
                glyph = {none: red(glyph), blank: yellow(glyph), eq_base: bold(blue(glyph))}[rec[:type]]
                if rec[:type] == :none
                  locale     = magenta bold rec[:locale]
                  base_value = ''
                else
                  locale     = magenta rec[:locale]
                  begin
                    base_value = cyan rec[:base_value].try(:strip) || ''
                  rescue
                    base_value = cyan ''
                  end
                end
                [{value: locale, alignment: :center},
                 {value: glyph, alignment: :center},
                 magenta(rec[:key]),
                 base_value]
              }
            end
          else
            print_success 'Good job! No translations missing!'
          end
        end

        def unused_translations(recs = task.unused_keys)
          print_title unused_title(recs)
          if recs.present?
            print_table headings: [bold(magenta('i18n Key')), cyan("Base value (#{base_locale})")] do |t|
              t.rows = recs.map { |x| [magenta(x[0]), cyan(x[1])] }
            end
          else
            print_success 'Good job! Every translation is used!'
          end
        end

        private

        def print_title(title)
          $stderr.puts "#{bold cyan title.strip} #{dark "|"} #{bold "i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          $stderr.puts(bold green message)
        end

        private
        def indent(txt, n = 2)
          spaces = ' ' * n
          txt.gsub /^/, spaces
        end

        def print_table(opts, &block)
          puts ::Terminal::Table.new(opts, &block)
        end
      end
    end
  end
end
