require 'ostruct'
module I18n::Tasks
  class CommandsBase
    def locales_opt(value, default = nil)
      if value.is_a?(String)
        value = value.strip.split(/\s*\+\s*/).compact.presence
      end
      return i18n_task.locales if value == ['all']
      if value.present?
        value = value.map { |v| v == 'base' ? base_locale : v }
        value
      else
        default || i18n_task.locales
      end
    end

    class << self
      def cmds
        @cmds ||= {}.with_indifferent_access
      end

      def cmd(name, &block)
        cmds[name] = OpenStruct.new(@next_def)
        @next_def  = {}
        define_method(name, &block)
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
