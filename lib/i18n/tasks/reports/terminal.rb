# coding: utf-8
require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base
        include Term::ANSIColor

        def missing_keys(forest = task.missing_keys)
          forest = task.collapse_plural_nodes!(forest)
          if forest.present?
            print_title missing_title(forest)
            print_table headings: [cyan(bold(I18n.t('i18n_tasks.common.locale'))),
                                   cyan(bold I18n.t('i18n_tasks.common.key')),
                                   I18n.t('i18n_tasks.missing.details_title')] do |t|
              t.rows = sort_by_attr!(forest_to_attr(forest)).map do |a|
                [{value: cyan(a[:locale]), alignment: :center}, cyan(a[:key]), missing_key_info(a)]
              end
            end
          else
            print_success I18n.t('i18n_tasks.missing.none')
          end
        end

        def icon(type)
          glyph = missing_type_info(type)[:glyph]
          {missing_used: red(glyph), missing_diff: yellow(glyph)}[type]
        end

        def used_keys(used_tree = task.used_tree(source_occurrences: true))
          print_title used_title(used_tree)
          keys_nodes = used_tree.keys.to_a
          if keys_nodes.present?
            keys_nodes.sort! { |a, b| a[0] <=> b[0] }.each do |key, node|
              print_occurrences node, key
            end
          else
            print_error I18n.t('i18n_tasks.usages.none')
          end
        end

        def unused_keys(tree = task.unused_keys)
          keys = tree.root_key_values(true)
          if keys.present?
            print_title unused_title(keys)
            print_locale_key_value_table keys
          else
            print_success I18n.t('i18n_tasks.unused.none')
          end
        end

        def eq_base_keys(tree = task.eq_base_keys)
          keys = tree.root_key_values(true)
          if keys.present?
            print_title eq_base_title(keys)
            print_locale_key_value_table keys
          else
            print_info cyan('No translations are the same as base value')
          end
        end

        def show_tree(tree)
          print_locale_key_value_table tree.root_key_values(true)
        end

        def forest_stats(forest, stats = task.forest_stats(forest))
          text = if stats[:locale_count] == 1
                   I18n.t('i18n_tasks.data_stats.text_single_locale', stats)
                 else
                   I18n.t('i18n_tasks.data_stats.text', stats)
                 end
          title = bold(I18n.t('i18n_tasks.data_stats.title', stats.slice(:locales)))
          print_info "#{cyan title} #{cyan text}"
        end

        private

        def missing_key_info(leaf)
          if leaf[:type] == :missing_used
            first_occurrence leaf
          else
            "#{cyan leaf[:data][:missing_diff_locale]} #{leaf[:value].to_s.strip}"
          end
        end

        def print_occurrences(node, full_key = node.full_key)
          occurrences = node.data[:source_occurrences]
          puts "#{bold "#{full_key}"} #{green(occurrences.size.to_s) if occurrences.size > 1}"
          occurrences.each do |occurrence|
            puts "  #{key_occurrence full_key, occurrence}"
          end
        end

        def print_locale_key_value_table(locale_key_values)
          if locale_key_values.present?
            print_table headings: [bold(cyan(I18n.t('i18n_tasks.common.locale'))),
                                   bold(cyan(I18n.t('i18n_tasks.common.key'))),
                                   I18n.t('i18n_tasks.common.value')] do |t|
              t.rows = locale_key_values.map { |(locale, k, v)|
                [{value: cyan(locale), alignment: :center}, cyan(k), v.to_s]
              }
            end
          else
            puts 'ø'
          end
        end

        def print_title(title)
          log_stderr "#{bold title.strip} #{dark "|"} #{"i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          log_stderr bold(green "✓ #{I18n.t('i18n_tasks.cmd.encourage').sample} #{message}")
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

        def key_occurrence(full_key, info)
          location = green "#{info[:src_path]}:#{info[:line_num]}"
          source   = highlight_key(full_key, info[:line], info[:line_pos]..-1).strip
          "#{location} #{source}"
        end

        def highlight_key(full_key, line, range = (0..-1))
          line.dup.tap { |s| s[range] = s[range].sub(full_key) { |m| underline m } }
        end

        def first_occurrence(leaf)
          usages = leaf[:data][:source_occurrences]
          first  = usages.first
          [green("#{first[:src_path]}:#{first[:line_num]}"),
           ("(#{I18n.t 'i18n_tasks.common.n_more', count: usages.length - 1})" if usages.length > 1)].compact.join(' ')
        end
      end
    end
  end
end
