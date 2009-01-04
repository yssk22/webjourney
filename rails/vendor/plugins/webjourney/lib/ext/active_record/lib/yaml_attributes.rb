require 'yaml'

module ActiveRecord
  # The feature modules of ActiveRecord that enables specified column to be saved as a YAML text format.
  # Using this module, the property can not only be serialized but also be used as a text property.
  #
  #   class MyModel < ActiveRecord::Base
  #     yaml_attributes :col1, col2, ...
  #   end
  #
  # is same as
  #
  #   class MyModel < ActiveRecord::Base
  #     serialize :col1, col2, ..., Hash
  #   end
  #
  # and the properties are also '_text' prefixed methods.
  #
  #   mymodel.col1_text = <Yaml Loadable text>
  #   #=> set yaml formatted text directory to the property
  #
  #   <%= text_area 'mymodel', 'col1_text' %>
  #   #=> enables the user to edit the property in yaml format
  #
  module YamlAttributes
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Defines attributes as a yaml format text
      def yaml_attributes(klass=Hash, *attrs)
        # TODO wait a bug fix for #7283(ActiveRecord SerializationTypeMismatch raised inconsistently)
        # http://dev.rubyonrails.org/ticket/7283
        # It seems to be fixed
        attrs.each do |attr|
          # serialize attr, klass
          serialize attr
          self.class_eval %{
                     def #{attr.to_s}_text
                       if self.#{attr}
                           return self.#{attr}.to_yaml
                       else
                         return nil
                       end
                     end

                     def #{attr.to_s}_text=(val)
                       unless val.blank?
                         obj = YAML.load(val)
                          raise WeJourney::YamlSerializeError.new unless obj.is_a?(#{klass.to_s})
                         self.#{attr} = obj
                       else
                         self.#{attr} = nil
                       end
                     end
          }
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::YamlAttributes
