module WebJourney
  module Controller
    module IsComponentPage
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        def is_component_page(options = {})
          write_inheritable_attributes(:is_component_page_option, options)
        end
      end

      module InstanceMethods
      end
    end
  end
end

ActionController::Base::send :include, WebJourney::Widgets::IsComponentPage
