class ApplicationController < ActionController::Base
  helper :all
  helper_method :current_user
  if RAILS_ENV == "test"
    # to work with functional test
    protect_from_forgery :secret => "test_webjourney_secret_key"
  else
    protect_from_forgery
  end
  before_filter { |ctrl|
    if defined?(SLEEP_BEFORE_FILTER) &&
        SLEEP_BEFORE_FILTER > 0
      sleep SLEEP_BEFORE_FILTER
    end
  }
end

module WebJourney
  module Controllers
    module Application
      def self.append_features(base)
        super
        base.send(:extend,  ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def require_roles(*args)
          options = args.extract_options!
          has_role_args = args << { :any => options[:any] && true }
          self.send :before_filter, options do |controller|
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
        def set_flash(key, msg, *args)
          body = sprintf(msg, *args)
          flash[key] = body
          logger.wj_debug "flash[:#{key}] = #{body}"
        end

        def set_flash_now(key, msg, *args)
          body = sprintf(msg, *args)
          flash.now[key] = body
          logger.wj_debug "flash.now[:#{key}] = #{body}"
        end


        # Raise AuthenticationRequiredError or ForbiddenError
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

        def forbidden!(msg=nil)
          raise WebJourney::ForbiddenError.new(msg)
        end

        def client_error!(msg=nil)
          raise WebJourney::ClientRequestError.new(msg)
        end
        alias :client_request_error! :client_error!

        # Raise NotFoundError
        def not_found!(msg=nil)
          raise WebJourney::NotFoundError.new(msg)
        end

        # Raise MethodNotAllowedError
        def method_not_acceptable!(msg=nil)
          raise WebJourney::MethodNotAllowedError.new(msg)
        end

        # Get an user object on the current session.
        def get_current_user
          @current_user ||= WjUser.find(session[:wj_current_user_id]) rescue WjUser::BuiltIn::Anonymous.me
        end
        alias :current_user :get_current_user

        # Set an user object on the current session
        # if <tt>user</tt> is nil, then clear current_user, that is to say, logout.
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

        def respond_to_error(resource, status=400)
          return respond_to_nothing(status) if resource.blank?
          respond_to_resource(resource, status)
        end

        def respond_to_nothing(status=200)
          respond_to do |format|
            format.xml  { render :nothing => true, :status => status }
            format.json { render :nothing => true, :status => status }
          end
        end

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
    end
  end
end

ApplicationController.send :include, WebJourney::Controllers::Application
