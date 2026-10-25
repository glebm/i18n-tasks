# frozen_string_literal: true

class AdjacentStrings
  def static
    I18n.t("adjacent.split" \
           ".key")
  end

  def dynamic
    I18n.t("adjacent.#{section}" \
           ".ignored")
  end
end
