class WebJourney::ComponentPageController < WebJourney::ComponentController
  layout :select_layout
  before_filter :load_component_page
  before_filter :set_has_navigation
  attr_reader :page
  helper_method :page
  helper_method :has_navigation?
  helper_method :set_title

  helper WebJourney::ComponentHelper
  helper WebJourney::ComponentPageHelper

  def set_title(title)
    @_title = title
  end

  def has_navigation?
    @has_navigation
  end

  protected
  def select_layout
    layout = params[:_layout] || request.headers["X-WebJourney-Layout"] || "page"
    logger.wj_debug("Resolved layout: #{layout}")
    logger.wj_debug("View paths: #{view_paths.inspect}")
    case layout
    when "page"
      "webjourney/component_#{layout}"
    else
      nil
    end
  end

  def load_component_page
    c, p = self.controller_path.to_s.split("/")
    @page = WjComponentPage.get(c, p)
    unless @page
      logger.wj_debug("component page is requested but not found. Please check Component Page is registered.")
      logger.wj_debug("Component name: #{c}, Page name: #{p}")
      raise WebJourney::NotFoundError.new
    end
    true
  end

  def set_has_navigation
    path = File.join(RAILS_ROOT, "components", self.controller_path, "_navigation.html.erb")
    logger.wj_debug("nv_path :  #{path}")
    @has_navigation = File.exist?(path)
    true
  end

end

module WebJourney
  module Controllers
    module ComponentPage
      def self.append_features(base)
        super
        base.send(:extend,  ClassMethods)
        base.send(:include, InstanceMethods)
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

      module InstanceMethods
      end
    end
  end
end

WebJourney::ComponentPageController.send :include, WebJourney::Controllers::ComponentPage
