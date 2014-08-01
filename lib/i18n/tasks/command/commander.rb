# coding: utf-8
require 'i18n/tasks/slop_command'
require 'i18n/tasks/reports/terminal'
require 'i18n/tasks/reports/spreadsheet'

module I18n::Tasks
  module Command
    class Commander
      include ::I18n::Tasks::Logging

      def initialize(i18n = nil)
        @i18n = i18n
      end

      def safe_run(name, opts)
        begin
          coloring_was             = Term::ANSIColor.coloring?
          Term::ANSIColor.coloring = ENV['I18N_TASKS_COLOR'] || STDOUT.isatty
          run name, opts
        rescue CommandError => e
          log_error e.message
          log_verbose e.backtrace * "\n"
          exit 78
        ensure
          Term::ANSIColor.coloring = coloring_was
        end
      end

      def run(name, opts = {})
        name = name.to_sym
        public_name = name.to_s.tr '_', '-'
        SlopCommand.parse_opts! opts, self.class.cmds[name][:opt], self
        if opts.empty?
          log_verbose "run #{public_name} without arguments"
          send name
        else
          log_verbose "run #{public_name} with #{opts.map { |k, v| "#{k}=#{v}" } * ' '}"
          send name, opts
        end
      end

      def set_internal_locale!
        I18n.locale = i18n.internal_locale
      end

      protected

      def terminal_report
        @terminal_report ||= I18n::Tasks::Reports::Terminal.new(i18n)
      end

      def spreadsheet_report
        @spreadsheet_report ||= I18n::Tasks::Reports::Spreadsheet.new(i18n)
      end

      def desc(name)
        self.class.cmds.try(:[], name).try(:desc)
      end

      def i18n
        @i18n ||= I18n::Tasks::BaseTask.new
      end

      delegate :base_locale, :t, to: :i18n
    end
  end
end
