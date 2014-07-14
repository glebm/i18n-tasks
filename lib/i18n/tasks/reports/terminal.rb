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
            keys_attr = sort_by_attr! forest_to_attr(forest), {locale: :asc, type: :desc, key: :asc}
            print_table headings: [cyan(bold('Locale')), cyan(bold 'Key'), 'Info'] do |t|
              t.rows = keys_attr.map do |a|
                locale, key = a[:locale], a[:key], a[:type]
                if a[:type] == :missing_used
                  occ = a[:data][:source_locations]
                  first = occ.first
                  info = [green("#{first[:src_path]}:#{first[:line_num]}"),
                          ("(#{occ.length - 1} more)" if occ.length > 1)].compact.join(' ')
                else
                  info = a[:value].to_s.strip
                end
                [{value: cyan(locale), alignment: :center},
                 cyan(key),
                 wrap_string(info, 60)]
              end
            end
          else
            print_success 'No translations missing!'
          end
        end

        def icon(type)
          glyph = missing_types[type][:glyph]
          {missing_used: red(glyph), missing_diff: yellow(glyph)}[type]
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
          keys = tree.root_key_values(true)
          print_title unused_title(keys)
          if keys.present?
            print_locale_key_value_table keys
          else
            print_success 'Every translation is used!'
          end
        end

        def eq_base_keys(tree = task.eq_base_keys)
          keys = tree.root_key_values(true)
          print_title eq_base_title(keys)
          if keys.present?
            print_locale_key_value_table keys
          else
            print_info cyan('No translations are the same as base value')
          end
        end

        def show_tree(tree)
          print_locale_key_value_table tree.root_key_values(true)
        end

        private

        def print_locale_key_value_table(locale_key_values)
          if locale_key_values.present?
            print_table headings: [bold(cyan('Locale')), bold(cyan('Key')), 'Value'] do |t|
              t.rows = locale_key_values.map { |(locale, k, v)| [{value: cyan(locale), alignment: :center}, cyan(k), v.to_s] }
            end
          else
            puts 'ø'
          end
        end

        def print_title(title)
          log_stderr "#{bold title.strip} #{dark "|"} #{"i18n-tasks v#{I18n::Tasks::VERSION}"}"
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

        def wrap_string(s, max)
          chars = []
          dist = 0
          s.chars.each do |c|
            chars << c
            dist += 1
            if c == "\n"
              dist = 0
            elsif dist == max
              dist = 0
              chars << "\n"
            end
          end
          chars = chars[0..-2] if chars.last == "\n"
          chars.join
        end
      end
    end
  end
end
