class A
  def what
    # STI: Car < Vehicle < ApplicationRecord
    Car.human_attribute_name(:make)
    Car.model_name.human(count: 2)
  end
end
