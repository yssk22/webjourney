require File.join(File.dirname(__FILE__), "javascript_generator")

module WebJourney
  module Widgets
    module IsComponentPage
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        # is_component_page DSL.
        # It is the signature of the controller that implies the component page.
        # The request is received by the url /components/[component]/[page]/[action]
        def is_component_page(options = {})
          self.send :include, WebJourney::Widgets::IsComponentPage::InstanceMethods
          self.send :view_paths=, [File.join(RAILS_ROOT, "app/views"), File.join(RAILS_ROOT, "components", self.controller_path, "../..")]
          self.send :init_gettext, self.to_s.underscore.split("/").first
          self.send :layout, :select_layout
          if options[:title]
            self.send :before_filter do |controller|
              controller.assigns[:title] = options[:title]
            end
          end
          # check the permission with default key
          # only checked when the controller_path is registered as component page.
          component, page = self.controller_path.to_s.split("/")
          if WjComponentPage.get(component, page)
            require_same_roles_as self.controller_path
          end

          write_inheritable_attribute :is_component_page, true
        end

        # Access checker utility method.
        # example:
        #   require_same_roles_as "management", :only => :show
        #   # => the show action requires the same role as the "management" controller.
        def require_same_roles_as(component_page, *filters)
          self.send :before_filter, *filters do |controller|
            component, page = component_page.to_s.split("/")
            logger.app_debug "accessing require_same_role_as(#{component_page})"
            # if not {component}/{page} format, then the controller should be in the same component.
            unless page
              page      = component
              component = controller.class.to_s.underscore.split("/").first
            end
            required = WjComponentPage.get(component, page)
            if required
              unless required.permit_role_of?(controller.current_user)
                logger.app_info "The request user(#{controller.current_user.login_name}) is rejected to access #{component}/#{page}"
                controller.assigns[:title] = "You cannot access this page."
                controller.raise_access_reject()
              end
            else
              raise WebJourney::ApplicationError.new("Server program invalid. It can not find the souorce of ACL.")
            end
            logger.app_info "Passed access checking in require_same_role_as(#{component_page})"
          end
        end
      end

      module InstanceMethods
        protected
        def select_layout
          # IE7 does not send a text/html header in Accept field
          # so that only :_layout parameter is checked.
          # if request.format == Mime::HTML
          case params[:_layout]
          when "page"
            "component_page"
          else
            nil
          end
        end
      end
    end
  end
end

ActionController::Base::send :include, WebJourney::Widgets::IsComponentPage

=begin
module WebJourney
  module Widgets
    module IsComponentPage
      def self.append_features(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        # is_component_page DSL.
        # It is the signature of the controller that implies the component page.
        # The request is received by the url /components/[layout]/[component]/[page]/[action]
        #
        # for example::
        #    /components/page/system/login/index  #=> 'index' action defined in system/login_controller.rb with 'page' layout
        #    /components/block/system/login/index #=> 'index' action defined in system/login_controller.rb with 'block' layout
        #
        def is_component_page(options = { })
          self.send :include, WebJourney::Widgets::IsComponentPage::InstanceMethods
          hide_action :instance, :page
          self.send :helper_method, :instance
          self.send :helper_method, :page
          self.send :helper_method, :js_object
          self.send :helper, WebJourney::Widgets::WidgetHelper

          self.send :before_filter, :is_component_page_before_filter
          self.send :after_filter , :is_component_page_after_filter
          self.send :layout, :select_layout
          # In Rails 2.0, :template_root= method is unavailable
          # self.send :template_root=, File.join(RAILS_ROOT, "components", self.controller_path, "../..")
          self.send :view_paths=, File.join(RAILS_ROOT, "components", self.controller_path, "../..")

          self.send :init_gettext, self.to_s.underscore.split("/").first
        end
      end

      module InstanceMethods
        # Returns WjComponentPage instance
        def instance
          @page
        end

        alias :page :instance

        def js_object
          @js_object
        end

        protected
        # select the layout indicated in the url (It should be passed by Routs configuration)
        def select_layout
          raise WebJourney::ClientRequestError.new("invalid layout request") unless %w(page block body).include?(params[:layout])
          return "core/wj_component_page_#{params[:layout]}"
        end

        def is_component_page_before_filter
          component, page = params[:controller].split('/')
          @page = WjComponentPage.get(component, page)
          raise WebJourney::NotFoundError unless @page
          # permission check
          unless @page.permit_role_of?(current_user)
            if current_user.is_anonymous?
              raise WebJourney::AuthenticationRequiredError
            else
              raise WebJourney::ForbiddenError.new
            end
          end
          # OK
          @js_object = JavaScriptObject::JsWjComponentPageWidget.new(@page)
          @component_menu = WjComponent.select_for(current_user)
        end

        def is_component_page_after_filter

        end

      end
    end
  end
end
=end

