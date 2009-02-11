require 'openid'
require 'openid/store/filesystem'
class System::LoginController < WebJourney::Component::PageController
  module Msg
    PASSWORD_LOGIN_SUCCESSFUL  = "Authentication passed (%s)."
    PASSWORD_LOGIN_FAILED      = "Invalid Login Name or Password."
    OPENID_NEGOTIATION_FAILED  = "Failed to negotiate with your OpenID provider."
    OPENID_LOGIN_FAILED        = "Invalid OpenID."
  end

  # [Redirector]
  # Login page redirector. This action always redirect the client to the <tt>with_password</tt> page.
  def index
    redirect_login_page
  end

  # [Page]
  # Login with password.
  def with_password
    if request.method == :post
      process_login_with_password
    end
  end

  # [Page]
  # Login with OpenID.
  def with_open_id
    if request.method == :post
      process_login_with_open_id
    end
  end

  # [Page]
  # Register with password(LocalDB)
  def register_with_password
    set_title "Register With Password"
    forbidden! unless WjConfig.instance.account_allow_local_db_register
  end

  # [Page]
  # Register with Open ID
  def register_with_open_id
    set_title "Register With OpenID"
    forbidden! unless WjConfig.instance.account_allow_open_id_register
  end

  # [Page]
  # Reset password
  def reset_password
    set_title "Reset Password"
    request_account_to_reset_password if request.method == :post
  end

  # [Page][Not In Navigation]
  # Activation page for LocalDB user
  def activation_form
    set_title "Activate Account"
    check_account_status(:prepared)
  end

  # [Page][Not In Navigation]
  # Reset password page for LocalDB user
  def reset_password_form
    check_account_status(:active)
    set_title "Reset password"
  end

  # [Action]
  # Login URI endpoint for OpenID (send consumer request)
  def begin_authentication_with_open_id
    redirect_to :action => "index" if request.method == :post
  end

  # [Redirector]
  # Login URI endpoint for OpenID (redirect point from provider)
  def end_authentication_with_open_id
    redirect_to :action => "index" if request.method != :get
  end


  def with_open_id_confirmed
    res = consumer.complete(params.reject{|k,v|
                              request.path_parameters[k]
                            }, open_id_return_to)
    case res.status
    when OpenID::Consumer::SUCCESS
      user = WjUser.find_by_open_id_uri(params["openid.identity"])
      if user
        user.activate
        set_current_user(user)
        redirect_to mypage_system_account_path(user.login_name)
      else
        redirect_to :action => :register_with_open_id
      end
    when OpenID::Consumer::CANCEL
      flash.now[:error] = "You must allow this site(#{open_id_realm}) on your OpenID provider."
    when OpenID::Consumer::FAILURE
      flash.now[:error] = "OpenID authentication failed. Please check your OpenID site.."
    else
      logger.wj_info("OpenID confirmed with uknown status(#{res.status})")
    end
  end

  def logout
    set_current_user(nil)
    redirect_to :action => "index"
  end

  private
  def redirect_login_page
    redirect_to :action => "with_password"
  end

  def process_login_with_password
    @account = WjUser.find_by_login_name(params[:account][:login_name])
    if !@account.nil? && @account.authenticate(:password => params[:account][:password])
      set_current_user(@account)
      set_flash_now(:info, Msg::PASSWORD_LOGIN_SUCCESSFUL, @account.login_name)
      redirect_to mypage_system_account_path(@account.login_name)
    else
      set_flash_now(:error, Msg::PASSWORD_LOGIN_FAILED)
      render :status => 400
    end
  end

  def process_login_with_open_id
    uri = params[:account][:open_id_uri]
    if WjUser.find_by_open_id_uri(uri)
      begin
        return open_id_begin(uri)
      rescue => e
        logger.wj_error "Failed to begin OpenID Authentication : #{uri}"
        logger.wj_error "(#{$!})"
        logger.wj_error e.backrace.join("\n")
        set_flash_now(:error, Msg::OPENID_NEGOTIATION_FAILED)
        render :status => 400
      end
    else
      set_flash_now(:error, Msg::OPENID_LOGIN_FAILED)
      render :status => 400
    end
  end


  def check_account_status(status)
    @account = WjUser.find_by_login_name(params[:login_name])
    not_found! unless @account
    not_found! unless @account.request_passcode == params[:request_passcode]
    not_found! unless @account.status == WjUser::Status[status]
    @account
  end

  def consumer
    unless @consumer
      dir = File.join(RAILS_ROOT, "tmp", "webjourney", "idstore")
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    @consumer
  end

  def open_id_begin(uri)
    req = consumer.begin(uri)
    return redirect_to(req.redirect_url(open_id_realm,
                                        open_id_return_to))
  end

  def open_id_realm
    # "components/system/accounts/method" is removed from the url.
    url_seguments = url_for(:only_path => false).split("/")
    url_seguments.pop
    url_seguments.pop
    url_seguments.pop
    url_seguments.pop
    url_seguments.join("/") + "/"
  end



  def url_for_reset_password_confirmation(account)
    url_for(:controller => "login",
            :action => "reset_password_form",
            :params => {
              :login_name => account.login_name,
              :request_passcode => account.request_passcode
            })
  end

  def open_id_return_to
    url_for({ :action => "with_open_id_confirmed" })
  end

end
