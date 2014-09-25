module I18n::Tasks
  module Command
    module Options
      module Trees
        include Command::DSL
        format_opt = proc { |type|
          enum_opt_attr :f, :format=, enum_opt(type),
                        proc { |valid, default|
                          I18n.t("i18n_tasks.cmd.args.desc.#{type}", valid_text: valid, default_text: default) },
                        proc { |value, valid|
                          I18n.t('i18n_tasks.cmd.errors.invalid_format', invalid: value, valid: valid * ', ') }
        }

        enum_opt :data_format, %w(yaml json keys)
        # i18n-tasks-use t('i18n_tasks.cmd.args.desc.data_format')
        cmd_opt :data_format, format_opt.call(:data_format)

        enum_opt :out_format, ['terminal-table', *enum_opt(:data_format), 'inspect']
        # i18n-tasks-use t('i18n_tasks.cmd.args.desc.out_format')
        cmd_opt :out_format, format_opt.call(:out_format)

        def print_forest(forest, opt, version = :show_tree)
          format = opt[:format].to_s
          case format
            when 'terminal-table'
              terminal_report.send(version, forest)
            when 'inspect'
              puts forest.inspect
            when 'keys'
              puts forest.key_names(root: true)
            when *enum_opt(:data_format)
              puts i18n.data.adapter_dump forest.to_hash(true), format
          end
        end

        def opt_forest_arg_or_stdin!(opt, format = opt[:format])
          src = opt[:arguments].try(:shift) || $stdin.read
          parse_forest(src, format)
        end

        def opt_forests_stdin_args!(opt, num = false, format = opt[:format])
          args = opt[:arguments] || []
          if opt[:nostdin]
            sources = []
          else
            sources = [$stdin.read]
            num     -= 1 if num
          end
          if num
            num.times { sources << args.shift }
          else
            sources += args
            args.clear
          end
          sources.map { |src| parse_forest(src, format) }
        end

        def opt_forests_merged_stdin_args!(opt)
          opt_forests_stdin_args!(opt).inject(i18n.empty_forest) { |result, forest|
            result.merge! forest
          }
        end

        def parse_forest(src, format)
          if !src
            raise CommandError.new(I18n.t('i18n_tasks.cmd.errors.pass_forest'))
          end
          if format == 'keys'
            Data::Tree::Siblings.from_key_names parse_keys(src)
          else
            Data::Tree::Siblings.from_nested_hash i18n.data.adapter_parse(src, format)
          end
        end

        def parse_keys(src)
          explode_list_opt(src, /\s*[,\s\n]\s*/)
        end
      end
    end
  end
end
