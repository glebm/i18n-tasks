module I18n::Tasks
  class CommandsBase
    def locales_opt(value, default = nil)
      value = value.strip.split(/\s*\+\s*/).compact.presence if value.is_a?(String)
      if value.present?
        value
      else
        default || i18n_task.locales
      end
    end

    class << self
      def cmd(name, &block)
        @cmds ||= {}.with_indifferent_access
        @cmds[name] = {description: @next_desc}
        @next_desc = nil
        define_method(name, &block)
      end

      def desc(text)
        @next_desc = text
      end

      attr_reader :cmds
    end

    def desc(name)
      self.class.cmds.try(:[], name).try(:[], :description)
    end

    protected

    def i18n_task
      @i18n_task ||= I18n::Tasks::BaseTask.new
    end
    delegate :base_locale, to: :i18n_task
  end
end
