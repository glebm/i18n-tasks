# frozen_string_literal: true

module I18n
  module Tasks
    module RainbowUtils
      # TODO: This method can be removed after below PR is released.
      # https://github.com/sickill/rainbow/pull/53
      def self.faint_color(str)
        presenter = Rainbow(str)
        return presenter unless Rainbow.enabled
        Rainbow::Presenter.new(Rainbow::StringUtils.wrap_with_sgr(presenter, [2]))
      end
    end
  end
end
