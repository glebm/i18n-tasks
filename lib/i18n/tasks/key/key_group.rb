module I18n
  module Tasks
    class Key
      module KeyGroup
        attr_accessor :key_group

        def self.included(base)
          base.class_eval do
            extend ClassMethods
            delegate_to_attr :[], :key?
            delegate_to_attr_accessor :type, :locale
          end
        end

        def attr
          key_group.attr.merge @own_attr
        end

        def clone_orphan
          clone.tap { |k| k.key_group = nil }
        end

        module ClassMethods
          def delegate_to_attr_accessor(*methods)
            methods.each do |m|
              define_method(m) do
                @own_attr[m] || (kg = key_group) && kg.attr[m]
              end
            end
          end

          def delegate_to_attr(*methods)
            methods.each do |m|
              define_method(m) do |*args|
                @own_attr.send(m, *args) ||
                    (kg = key_group) && kg.attr.send(m, *args)
              end
            end
          end
        end
      end
    end
  end
end
