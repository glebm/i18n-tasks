module I18n::Tasks
  module Command
    module Commands
      module XLSX
        include Command::Collection

        cmd :xlsx_report,
            args: '[locale...]',
            desc: proc { I18n.t('i18n_tasks.cmd.desc.xlsx_report') },
            opt:  [cmd_opt(:locales),
                   {short: :p, long: :path=, desc: 'Destination path', conf: {default: 'tmp/i18n-report.xlsx'}}]

        def xlsx_report(opt = {})
          begin
            require 'axlsx'
          rescue LoadError
            message = %Q(For spreadsheet report please add axlsx gem to Gemfile:\ngem 'axlsx', '~> 2.0')
            log_stderr Term::ANSIColor.red Term::ANSIColor.bold message
            exit 1
          end
          spreadsheet_report.save_report opt[:path], opt.except(:path)
        end
      end
    end
  end
end
