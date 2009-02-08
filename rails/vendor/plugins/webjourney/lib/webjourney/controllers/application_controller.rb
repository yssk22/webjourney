#
# WebJourney Application Controller base.
#
# == Application level features
#
# See WebJourney::Controllers::ApplicationFeatures
#
# == Using standard responders
#
# In the WebJourney standard, all the resources except HTML page is responded by using following methods as possible.
#
# - respond_to_success(resource)
# - respond_to_error(resource)
# - respond_to_nothing(status)
# - respond_to_resource(resource, status)
#
# The <tt>resource</tt> should have two methods, to_xml and to_json.
# The general responder instruction in the controller is as follows::
#
#   def show
#     @resource = Resource.find(...)
#     respond_to_success(@resource)
#   end
#
#   def update
#     @resource = Resource.find(...)
#     if @resource.save
#       respond_to_success(@resource)
#       # or respond_to_nothing()
#     else
#       respond_to_error(@resource)
#     end
#   end
#
class ApplicationController < ActionController::Base
  helper :all
  helper_method :current_user
  if RAILS_ENV == "test"
    # to work with functional test
    protect_from_forgery :secret => "test_webjourney_secret_key"
  else
    protect_from_forgery
  end
  # Set the flash string associated with the  <tt>key</tt>
  # This method logs the flash message into the log file.
  def set_flash(key, msg, *args)
    body = sprintf(msg, *args)
    flash[key] = body
    logger.wj_debug "flash[:#{key}] = #{body}"
  end

  # Set the flash.now string associated with the <tt>key</tt>
  # This method logs the flash message into the log file.
  def set_flash_now(key, msg, *args)
    body = sprintf(msg, *args)
    flash.now[key] = body
    logger.wj_debug "flash.now[:#{key}] = #{body}"
  end

  # Raise WebJourney::AuthenticationRequiredError or WebJourney::ForbiddenError
  def reject_access!(msg=nil)
    logger.wj_error("Access Rejected! (#{current_user.login_name})")
    if current_user.anonymous?
      raise WebJourney::AuthenticationRequiredError.new(msg) if msg
      raise WebJourney::AuthenticationRequiredError.new
    else
      raise WebJourney::ForbiddenError.new(msg) if msg
      raise WebJourney::ForbiddenError.new
    end
  end

  # Raise WebJourney::ForbiddenError
  def forbidden!(msg=nil)
    raise WebJourney::ForbiddenError.new(msg)
  end

  # Raise WebJourney::ClientError
  def client_error!(msg=nil)
    raise WebJourney::ClientRequestError.new(msg)
  end
  alias :client_request_error! :client_error!

  # Raise WebJourney::NotFoundError
  def not_found!(msg=nil)
    raise WebJourney::NotFoundError.new(msg)
  end

  # Raise WebJourney::MethodNotAllowedError
  def method_not_acceptable!(msg=nil)
    raise WebJourney::MethodNotAllowedError.new(msg)
  end

  # Returns an WjUser object on the current session.
  def get_current_user
    @current_user ||= WjUser.find(session[:wj_current_user_id]) rescue WjUser::BuiltIn::Anonymous.me
  end
  alias :current_user :get_current_user

  # Set an WjUser object on the current session.
  # If <tt>user</tt> is nil, then clear current_user, that is to say, logout.
  def set_current_user(user)
    assert_not_equal WjUser::BuiltIn::Anonymous.me, user
    if user
      session[:wj_current_user_id] = user.id if session
      @current_user = user
    else
      session[:wj_current_user_id] = nil if session
      @current_user = nil
    end
  end

  def get_authenticated_open_id
    @authenticated_open_id
  end
  alias :authenticated_open_id :get_authenticated_open_id

  def set_authenticated_open_id(open_id)
    @authenticated_open_id = open_id
  end

  # standard resource responders
  def respond_to_success(resource, status=200)
    return respond_to_nothing(status) if resource.blank?
    respond_to_resource(resource, status)
  end

  # standard resource responders
  def respond_to_error(resource, status=400)
    return respond_to_nothing(status) if resource.blank?
    respond_to_resource(resource, status)
  end

  # standard "nothing" responders
  def respond_to_nothing(status=200)
    respond_to do |format|
      format.xml  { render :nothing => true, :status => status }
      format.json { render :nothing => true, :status => status }
    end
  end


  # standard resource responders
  def respond_to_resource(resource, status)
    respond_to do |format|
      format.xml  { render :text => resource.to_xml,  :status => status }
      format.json { render :text => resource.to_json, :status => status }
    end
  end

  protected
  def rescue_action(e)
    if e.is_a?(WebJourney::ApplicationError)
      logger.wj_error "ApplicationError handled in global controller."
      logger.wj_error " - #{e.message} (HTTP #{e.http_status})"
      logger.wj_error " - #{e.backtrace.first}"
      err = {:errors => [{ :message => e.message }]}
      respond_to do |format|
        format.html {
          # TODO layout negotiation
          render :text => e.message, :status => e.http_status
        }
        format.xml  { render :text => err.to_xml,  :status => e.http_status}
        format.json { render :text => err.to_json, :status => e.http_status}
      end
    else
      if ENV["RAILS_ENV"] == "development"
        rescue_action_locally(e)
      else
        raise e
      end
    end
  end
end

module WebJourney
  module Controllers # :nodoc:
    module ApplicationFeatures
      def self.append_features(base)
        super
        base.send(:extend,  RoleBasedAccessControl)
      end

      #
      # This module defines common class methods used in any controllers.
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

ApplicationController.send :include, WebJourney::Controllers::ApplicationFeatures

