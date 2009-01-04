require File.join(File.dirname(__FILE__), "javascript_generator")

module WebJourney
  module Widgets
    module IsComponentController
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        #
        # is_component_controller DSL
        # This is the signature of the controller used in controllers under the components directory.
        #

        def is_component_controller
          self.send :view_paths=, File.join(RAILS_ROOT, "components", self.controller_path, "../..")
        end
      end
    end
  end
end
