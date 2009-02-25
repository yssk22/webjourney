module WebJourney # :nodoc:
  module Component # :nodoc:
    module Features # :nodoc:
      #
      # This module defines role based access control mechanism used in any controllers.
      # It is almost the same as WebJourney::Features::RoleBasedAccessControl.
      # The difference is that this module is include component page dependency.
      #
      # The usage of require_roles method, see WebJourney::Features::RoleBasedAccessControl.
      #
      module RoleBasedAccessControl
        def self.append_features(base)
          super
          base.send(:extend,  ClassMethods)
        end

        module ClassMethods
          def require_roles(*args)
            write_inheritable_attribute(:require_roles_for_menu_item, args.dup)
            options = args.extract_options!
            has_role_args = args << {:all => (options[:all] && true)}
            self.send :before_filter do |controller|
              unless controller.current_user.has_roles?(*has_role_args)
                logger.wj_debug "Access Rejected!!!"
                logger.wj_debug "Required Roles : #{has_role_args.join(",")}"
                logger.wj_debug "User Roles : #{controller.current_user.wj_roles.map(&:name).join(",")}"
                controller.reject_access!
              end
            end
          end
        end
      end
    end
  end
end