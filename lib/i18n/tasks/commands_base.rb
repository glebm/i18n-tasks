require 'ostruct'
module I18n::Tasks
  class CommandsBase
    include ::I18n::Tasks::Logging

    def initialize(i18n_task = nil)
      @i18n_task = i18n_task
    end

    def locales_opt(locales)
      return i18n_task.locales if locales == ['all'] || locales == 'all'
      if locales.present?
        locales = Array(locales).map { |v| v.strip.split(/\s*[\+,:]\s*/).compact.presence if v.is_a?(String) }.flatten
        locales = locales.map(&:presence).compact.map { |v| v == 'base' ? base_locale : v }
        locales
      else
        i18n_task.locales
      end
    end

    def parse_locales!(opt)
      opt[:locales] = locales_opt(opt[:arguments].presence || opt[:locales]).tap do |locales|
        log_verbose "locales for the command are #{locales.inspect}"
      end
    end

    class << self
      def cmds
        @cmds ||= {}.with_indifferent_access
      end

      def cmd(name, &block)
        cmds[name] = OpenStruct.new(@next_def)
        @next_def  = {}
        define_method name do |*args|
          begin
            instance_exec *args, &block
          rescue CommandError => e
            log_error e.message
            exit 78
          end
        end
      end

      def desc(text)
        next_def[:desc] = text
      end

      def opts(&block)
        next_def[:opts] = block
      end

      private
      def next_def
        @next_def ||= {}
      end
    end

    def desc(name)
      self.class.cmds.try(:[], name).try(:desc)
    end

    def i18n_task
      @i18n_task ||= I18n::Tasks::BaseTask.new
    end

    delegate :base_locale, :t, to: :i18n_task
  end
end
