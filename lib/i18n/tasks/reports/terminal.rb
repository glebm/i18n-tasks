# frozen_string_literal: true
require 'i18n/tasks/reports/base'
require 'terminal-table'
module I18n
  module Tasks
    module Reports
      class Terminal < Base # rubocop:disable Metrics/ClassLength
        include Term::ANSIColor

        def missing_keys(forest = task.missing_keys)
          forest = collapse_missing_tree! forest
          if forest.present?
            print_title missing_title(forest)
            print_table headings: [cyan(bold(I18n.t('i18n_tasks.common.locale'))),
                                   cyan(bold(I18n.t('i18n_tasks.common.key'))),
                                   I18n.t('i18n_tasks.missing.details_title')] do |t|
              t.rows = sort_by_attr!(forest_to_attr(forest)).map do |a|
                [{ value: cyan(format_locale(a[:locale])), alignment: :center },
                 format_key(a[:key], a[:data]),
                 missing_key_info(a)]
              end
            end
          else
            print_success I18n.t('i18n_tasks.missing.none')
          end
        end

        def icon(type)
          glyph = missing_type_info(type)[:glyph]
          { missing_used: red(glyph), missing_diff: yellow(glyph) }[type]
        end

        def used_keys(used_tree = task.used_tree)
          # For the used tree we may have usage nodes that are not leaves as references.
          keys_nodes = used_tree.nodes.select { |node| node.data[:occurrences].present? }.map do |node|
            [node.full_key(root: false), node]
          end
          print_title used_title(keys_nodes, used_tree.first.root.data[:key_filter])
          # Group multiple nodes
          if keys_nodes.present?
            keys_nodes.sort! { |a, b| a[0] <=> b[0] }.each do |key, node|
              print_occurrences node, key
            end
          else
            print_error I18n.t('i18n_tasks.usages.none')
          end
        end

        def unused_keys(tree = task.unused_keys)
          keys = tree.root_key_value_data(true)
          if keys.present?
            print_title unused_title(keys)
            print_locale_key_value_data_table keys
          else
            print_success I18n.t('i18n_tasks.unused.none')
          end
        end

        def eq_base_keys(tree = task.eq_base_keys)
          keys = tree.root_key_value_data(true)
          if keys.present?
            print_title eq_base_title(keys)
            print_locale_key_value_data_table keys
          else
            print_info cyan('No translations are the same as base value')
          end
        end

        def show_tree(tree)
          print_locale_key_value_data_table tree.root_key_value_data(true)
        end

        def forest_stats(forest, stats = task.forest_stats(forest))
          text  = if stats[:locale_count] == 1
                    I18n.t('i18n_tasks.data_stats.text_single_locale', stats)
                  else
                    I18n.t('i18n_tasks.data_stats.text', stats)
                  end
          title = bold(I18n.t('i18n_tasks.data_stats.title', stats.slice(:locales)))
          print_info "#{cyan title} #{cyan text}"
        end

        def mv_results(results)
          results.each do |(from, to)|
            if to
              print_info "#{cyan from} #{bold(yellow('⮕'))} #{cyan to}"
            else
              print_info "#{red from}#{bold(red(' 🗑'))}"
            end
          end
        end

        private

        def missing_key_info(leaf)
          if leaf[:type] == :missing_used
            first_occurrence leaf
          else
            "#{cyan leaf[:data][:missing_diff_locale]} "\
            "#{format_value(leaf[:value].is_a?(String) ? leaf[:value].strip : leaf[:value])}"
          end
        end

        def format_key(key, data)
          if data[:ref_info]
            from, to = data[:ref_info]
            resolved = key[0...to.length]
            after    = key[to.length..-1]
            "  #{yellow from}#{cyan after}\n#{bold(yellow('⮕'))} #{bold yellow resolved}"
          else
            cyan(key)
          end
        end

        def format_value(val)
          val.is_a?(Symbol) ? "#{bold(yellow('⮕ '))}#{yellow(val.to_s)}" : val.to_s.strip
        end

        def format_reference_desc(node_data)
          return nil unless node_data
          case node_data[:ref_type]
          when :reference_usage
            bold(yellow('(ref)'))
          when :reference_usage_resolved
            bold(yellow('(resolved ref)'))
          when :reference_usage_key
            bold(yellow('(ref key)'))
          end
        end

        def print_occurrences(node, full_key = node.full_key)
          occurrences = node.data[:occurrences]
          puts [bold(full_key.to_s),
                format_reference_desc(node.data),
                (green(occurrences.size.to_s) if occurrences.size > 1)].compact.join ' '
          occurrences.each do |occurrence|
            puts "  #{key_occurrence full_key, occurrence}"
          end
        end

        def print_locale_key_value_data_table(locale_key_value_datas)
          if locale_key_value_datas.present?
            print_table headings: [bold(cyan(I18n.t('i18n_tasks.common.locale'))),
                                   bold(cyan(I18n.t('i18n_tasks.common.key'))),
                                   I18n.t('i18n_tasks.common.value')] do |t|
              t.rows = locale_key_value_datas.map { |(locale, k, v, data)|
                [{ value: cyan(locale), alignment: :center }, format_key(k, data), format_value(v)]
              }
            end
          else
            puts 'ø'
          end
        end

        def print_title(title)
          log_stderr "#{bold title.strip} #{dark '|'} #{"i18n-tasks v#{I18n::Tasks::VERSION}"}"
        end

        def print_success(message)
          log_stderr bold(green("✓ #{I18n.t('i18n_tasks.cmd.encourage').sample} #{message}"))
        end

        def print_error(message)
          log_stderr(bold(red(message)))
        end

        def print_info(message)
          log_stderr message
        end

        def indent(txt, n = 2)
          txt.gsub(/^/, ' ' * n)
        end

        def print_table(opts, &block)
          puts ::Terminal::Table.new(opts, &block)
        end

        def key_occurrence(full_key, occurrence)
          location = green "#{occurrence.path}:#{occurrence.line_num}"
          source   = highlight_key(occurrence.raw_key || full_key, occurrence.line, occurrence.line_pos..-1).strip
          "#{location} #{source}"
        end

        def first_occurrence(leaf)
          # @type [I18n::Tasks::Scanners::KeyOccurrences]
          occurrences = leaf[:data][:occurrences]
          # @type [I18n::Tasks::Scanners::Occurrence]
          first = occurrences.first
          [
            green("#{first.path}:#{first.line_num}"),
            ("(#{I18n.t 'i18n_tasks.common.n_more', count: occurrences.length - 1})" if occurrences.length > 1)
          ].compact.join(' ')
        end

        def highlight_key(full_key, line, range = (0..-1))
          line.dup.tap do |s|
            s[range] = s[range].sub(full_key) do |m|
              highlight_string m
            end
          end
        end

        module HighlightUnderline
          def highlight_string(s)
            underline s
          end
        end

        module HighlightOther
          def highlight_string(s)
            yellow s
          end
        end

        if Gem.win_platform?
          include HighlightOther
        else
          include HighlightUnderline
        end
      end
    end
  end
end
