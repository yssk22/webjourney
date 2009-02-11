#
# WebJourney Application Controller base. This class defines some utilities to standardize WebJourney applications.
# In WebJourney component application, you can select three types of controllers as follows::
#
# - WebJourney::WidgetController
# - WebJourney::ComponentPageController
# - WebJourney::ResourceController
#
# == Application level features
#
# The declaratory methods is described at WebJourney::Controllers::ApplicationFeatures
#
# == Using errors
#
# Simplify to repsonse HTTP error, use following methods::
#
# - client_error!(msg)
# - forbidden!(msg)
# - reject_access!(msg)
# - not_found!(msg)
# - method_not_allowed!(msg)
#
# == Using flash
#
# As general rails applications, flash object is available to send a message to the user.
# the flash messages can be logged with following methods ::
#
# - set_flash(key, str, *args)
# - set_flash_now(key, str, *args)
#
# == Refer the access user
#
# You can refere the current access user object (kind of WjUser) using current_user method.
#
class WebJourney::ApplicationController < ActionController::Base
  include WebJourney::Features::RoleBasedAccessControl
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

  # Raise WebJourney::Errors::AuthenticationRequiredError or WebJourney::Errors::ForbiddenError
  def reject_access!(msg=nil)
    logger.wj_error("Access Rejected! (#{current_user.login_name})")
    if current_user.anonymous?
      raise WebJourney::Errors::AuthenticationRequiredError.new(msg) if msg
      raise WebJourney::Errors::AuthenticationRequiredError.new
    else
      raise WebJourney::Errors::ForbiddenError.new(msg) if msg
      raise WebJourney::Errors::ForbiddenError.new
    end
  end

  # Raise WebJourney::Errors::ForbiddenError
  def forbidden!(msg=nil)
    raise WebJourney::Errors::ForbiddenError.new(msg)
  end

  # Raise WebJourney::Errors::ClientError
  def client_error!(msg=nil)
    raise WebJourney::Errors::ClientRequestError.new(msg)
  end
  alias :client_request_error! :client_error!

  # Raise WebJourney::Errors::NotFoundError
  def not_found!(msg=nil)
    raise WebJourney::Errors::NotFoundError.new(msg)
  end

  # Raise WebJourney::Errors::MethodNotAllowedError
  def method_not_allowed!(msg=nil)
    raise WebJourney::Errors::MethodNotAllowedError.new(msg)
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


  protected
  def rescue_action(e)
    if e.is_a?(WebJourney::Errors::ApplicationError)
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
