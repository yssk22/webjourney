class System::LoginPageController < WebJourney::Component::PageController
  # see API details at http://www.webjourney.org/doc/classes/WebJourney/Component/PageController.html
  # require_role :administrators, :only => :show
  # require_role :users

  def index
    redirect_to :action => "login_with_password"
  end

  def login_with_password
    set_title "Password User::Login"
  end

  def register_with_password
    set_title "Password User::Register"
  end

  def activation
    set_title "Password User::Account Activation"
    @account = WjUser::LocalDB.new
    @account.login_name = params[:login_name]
    @account.request_passcode= params[:request_passcode]
  end

  def reset_password
    set_title "Password User::Reset Password"
  end

  def confirm_reset_password
    set_title "Password User::Reset Password (Confirmation)"
    @account = WjUser::LocalDB.new
    @account.login_name = params[:login_name]
    @account.request_passcode= params[:request_passcode]
  end

  def login_with_open_id
    set_title "OpenID User::Login"
  end

  def register_with_open_id
    set_title "OpenID User::Register"
    uri = get_authenticated_open_id
    return redirect_to(:action => "login_with_open_id") unless uri
    @account = WjUser::OpenId.new
    @account.open_id_uri = uri
    @account.login_name = WjUser::OpenId.get_suggest_login_name(uri)
  end

  def logout
    set_current_user(nil)
    redirect_to :controller => "top", :action => "index"
  end
end
