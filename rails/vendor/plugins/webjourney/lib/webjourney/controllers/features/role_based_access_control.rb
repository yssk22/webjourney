module WebJourney
  module Features
    #
    # This module defines role based access control mechanism used in any controllers.
    #
    # == Role based access control
    #
    # To control access user, require_roles method can be used.
    #
    #   class FooController < ApplicationController
    #     require_roles :roleA, :roleB
    #     require_roles :roleC, :except => :show
    #     require_roles :role1, :only => :show
    #     require_roles :role2, :role3, :only => :edit, :any => true
    #   end
    #
    # - all actions require the user to have "roleA" and "roleB"
    # - all actions except "show" require the user to have "roleC"
    # - "show" action require the user to have "role1"
    # - "edit" action require the user to have "role2" or "role3"
    #
    module RoleBasedAccessControl
      def self.append_features(base)
        super
        base.send(:extend,  ClassMethods)
      end
      module ClassMethods
        # Define role requirements for the current user.
        # If access check fails, WebJourney::AuthenticationRequiredError or WebJourney::ForbiddenError is raised.
        #
        # <tt>args</tt> is a list of roles and the last parameter is an option if it is a Hash.
        # <tt>option</tt> is the same as :before_filter method in except the key :any.
        #
        # - <tt>:any</tt> - when true, the user can be accepted if he/she has at least one of the roles, not all (default is false).
        #
        def require_roles(*args)
          options = args.extract_options!
          has_role_args = args << { :any => options[:any] && true }
          self.send :before_filter, options do |controller|
            unless controller.current_user.has_roles?(*has_role_args)
              logger.wj_debug "Access Rejected!!!"
              logger.wj_debug "Required Roles : #{has_role_args.join(",")}"
              logger.wj_debug "User Roles     : #{controller.current_user.wj_roles.map(&:name).join(",")}"
              controller.reject_access!
            end
          end
        end
      end
    end
  end
end
