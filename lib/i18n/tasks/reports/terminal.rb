# coding: utf-8
require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base
        include Term::ANSIColor

        def missing_keys(forest = task.missing_keys)
          print_title missing_title(forest)

          if forest.present?
            print_info "#{bold 'Types:'} #{missing_types.values.map { |t| "#{t[:glyph]} #{t[:summary]}" } * ', '}"
            keys_data = sort_by_attr! forest_to_attr(forest), {locale: :asc, type: :asc, key: :asc}
            print_table headings: [magenta(bold('Locale')), bold('Type'), magenta(bold 'i18n Key'), bold(cyan "Base value (#{base_locale})")] do |t|
              t.rows = keys_data.map do |d|
                key    = d[:key]
                type   = d[:type]
                locale = d[:locale]
                glyph  = missing_types[type][:glyph]
                glyph  = {missing_from_base: red(glyph), missing_from_locale: yellow(glyph), eq_base: bold(blue(glyph))}[type]
                if type == :missing_from_base
                  locale     = magenta locale
                  base_value = ''
                else
                  locale     = magenta locale
                  base_value = task.t(key, base_locale).to_s.strip
                end
                [{value: locale, alignment: :center},
                 {value: glyph, alignment: :center},
                 magenta(key),
                 cyan(base_value)]
              end
            end
          else
            print_success 'No translations missing!'
          end
        end

        def used_keys(used_tree = task.used_tree(source_locations: true))
          print_title used_title(used_tree)
          keys_nodes = used_tree.keys.to_a
          if keys_nodes.present?
            keys_nodes.sort! { |a, b| a[0] <=> b[0] }
            keys_nodes.each do |key, node|
              usages = node.data[:source_locations]
              puts "#{bold "#{key}"} #{green(usages.size.to_s) if usages.size > 1}"
              usages.each do |u|
                line = u[:line].dup.tap { |line|
                  line.strip!
                  line.sub!(/(.*?)(#{key})(.*)$/) { dark($1) + underline($2) + dark($3) }
                }
                puts "  #{green "#{u[:src_path]}:#{u[:line_num]}"} #{line}"
              end
            end
          else
            print_error 'No key usages found'
          end
        end

        def unused_keys(tree = task.unused_keys)
          keys = tree.root_key_values.sort { |a, b| a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1] }
          print_title unused_title(keys)
          if keys.present?
            print_table headings: [bold(magenta('Locale')), bold(magenta('i18n Key')), bold(cyan("Base value (#{base_locale})"))] do |t|
              t.rows = keys.map { |(locale, k, v)| [magenta(locale), magenta(k), cyan(v.to_s)] }
            end
          else
            print_success 'Every translation is used!'
          end
        end

        private

        def print_title(title)
          log_stderr "#{bold cyan title.strip} #{dark "|"} #{bold "i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          log_stderr(bold green ['Good job!', 'Well done!'].sample + ' ' + message)
        end

        def print_error(message)
          log_stderr(bold red message)
        end

        def print_info(message)
          log_stderr message
        end

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
