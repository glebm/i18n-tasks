# frozen_string_literal: true

module Prism
  class PrismController < ApplicationController
    class EmptyClass
    end

    before_action(:authenticate_user!)
    

    def index
    end

    def show
      @user = current_user
      %w[testing some keys]
      ["testing", "keys", t('.relative_key')]
      assign, multiple = "sha256=#{t("prism.show.assign")}", "sha256=#{t("prism.show.multiple")}"
    end
  end
end
