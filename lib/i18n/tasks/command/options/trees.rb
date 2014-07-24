module I18n::Tasks
  module Command
    module Options
      module Trees
        extend Command::DSL

        enum_opt :data_format, %w(yaml json keys)
        cmd_opt :data_format, enum_opt_attr(:f, :format=, enum_opt(:data_format)) { |valid_text, default_text|
          I18n.t('i18n_tasks.cmd.args.desc.data_format', valid_text: valid_text, default_text: default_text)
        }

        enum_opt :out_format, ['terminal-table', *enum_opt(:data_format), 'inspect']
        cmd_opt :out_format, enum_opt_attr(:f, :format=, enum_opt(:out_format)) { |valid_text, default_text|
          I18n.t('i18n_tasks.cmd.args.desc.out_format', valid_text: valid_text, default_text: default_text)
        }

        cmd_opt :keys, {
            short: :k,
            long:  :keys=,
            desc:  I18n.t('i18n_tasks.cmd.args.desc.keys'),
            conf:  {as: Array, delimiter: /[+:,]/, argument: true, optional: false}
        }

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
              puts i18n.data.adapter_dump forest, format
          end
        end

        INVALID_FORMAT_MSG = proc do |value, valid|
          I18n.t('i18n_tasks.cmd.errors.invalid_format', invalid: value, valid: valid * ', ')
        end

        def opt_output_format!(opt = {}, key = :format)
          opt[key] = parse_enum_opt opt[key], :out_format, &INVALID_FORMAT_MSG
        end

        def opt_data_format!(opt = {}, key = :format)
          opt[key] = parse_enum_opt opt[key], :data_format, &INVALID_FORMAT_MSG
        end

        def opt_args_keys!(opt = {})
          opt[:keys] = explode_list_opt(opt[:keys]) + Array(opt[:arguments])
        end

        def opt_forest_arg_or_stdin!(opt)
          src = opt[:arguments].try(:shift) || $stdin.read
          parse_forest(src, opt)
        end

        def opt_forests_stdin_args!(opt, num = false)
          args = opt[:arguments] || []
          if opt[:nostdin]
            sources = []
          else
            sources = [$stdin.read]
            num -= 1 if num
          end
          if num
            num.times { sources << args.shift }
          else
            sources += args
            args.clear
          end
          sources.map { |src| parse_forest(src, opt) }
        end

        def opt_forests_merged_stdin_args!(opt)
          opt_forests_stdin_args!(opt).inject(i18n.empty_forest) { |result, forest|
            result.merge! forest
          }
        end

        def parse_forest(src, opt = {})
          if !src
            raise CommandError.new(I18n.t('i18n_tasks.cmd.errors.pass_forest'))
          end
          format = opt_data_format!(opt)
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
