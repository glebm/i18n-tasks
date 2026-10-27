# frozen_string_literal: true

class AdjacentStrings
  def static
    I18n.t("adjacent.split" \
           ".key")
  end

  def three_parts
    I18n.t("adjacent" ".three" ".parts")
  end

  def scope
    I18n.t(:leaf, scope: "adjacent" ".scope")
  end

  def scope_array
    I18n.t(:leaf, scope: ["adjacent" ".array", :scope])
  end

  def attribute
    Product.human_attribute_name("status" ".active")
  end

  def dynamic
    I18n.t("adjacent.#{section}" \
           ".ignored")
  end
end
