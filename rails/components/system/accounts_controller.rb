class System::AccountsController < WebJourney::ComponentController
  before_filter :load_account, :only => [:show, :edit, :update, :mypage, :activation_form] # , :reset_password_form, :activation_form]
  before_filter :check_type_parameter, :only => [:new, :create]

  module Msg
    INVALID_TYPE_PARAMETER = "type must be 'password' or 'open_id'."
    ACCOUNT_CREATION_FAILURE = "Cannot register your account."
  end

  def index
    reject_access! unless current_user.has_roles?(:administrator)
    params[:class] = case params[:type]
                     when 'open_id'
                       WjUser::OpenId
                     when 'password'
                       WjUser::LocalDB
                     else
                       WjUser
                     end
    @accounts = WjUser.list(params)
  end

  # GET /components/system/accounts/new?type={type}
  def new;  end

  # POST /components/system/accounts
  def create
    if send "create_with_#{params[:type]}"
      redirect_to(system_account_path(@account.login_name))
    else
      set_flash_now(:error, Msg::ACCOUNT_CREATION_FAILURE)
      render :action => "new", :status => 400
    end
  end

  # GET /components/system/accounts/{account_id}/
  def show
    @title = "Account: #{@account.login_name}"
  end

  # GET /components/system/accounts/{account_id}/activation_form
  def activation_form
    
  end


  # GET /components/system/accounts/{account_id}/my_page
  def mypage
    page = WjPage.my_page_for(@account.login_name)
    redirect_to page_url(page._id)
  end

  # GET /components/system/accounts/{account_id}/edit
  def edit
    @partial = get_edit_view
  end

  def update
    not_found! if @account.status == WjUser::Status[:destroyed]
    case @account
    when WjUser::OpenId
      method_not_acceptable!("OpenID cannot be updated.")
    when WjUser::BuiltIn::Administrator
      update_administrator
    when WjUser::LocalDB
      update_local_db
    end
    @partial = get_edit_view
    render :action => "edit"
  end

  private
  def check_type_parameter
    case params[:type]
    when "password"
      forbidden! unless WjConfig.instance.account_allow_local_db_register
    when "open_id"
      forbidden! unless WjConfig.instance.account_allow_open_id_register
    else
      client_error!(Msg::INVALID_TYPE_PARAMETER)
    end
    true
  end

  def create_with_password
    @account = WjUser::LocalDB.prepare(params[:account][:login_name],
                                       params[:account][:email])
    return false if @account.new_record?
    # send notification mail
    System::Mailer.deliver_registration_confirmation(@account,
                                                     url_for(:controller => "login",
                                                             :action => "activation_form",
                                                             :params => {
                                                               :login_name => @account.login_name,
                                                               :request_passcode => @account.request_passcode
                                                             }))
    true
  end

  def create_with_open_id
    @account = WjUser::OpenId.prepare(params[:account][:login_name],
                                      params[:account][:open_id_uri])
    !@account.new_record?
  end

  def load_account
    @account = WjUser.find_by_login_name(params[:id])
    not_found! unless @account
    # status check
    case @account.status
    when WjUser::Status[:destroyed]
      not_found! unless current_user.has_roles?(:administrator)
    when WjUser::Status[:locked]
      reject_access! unless current_user.has_roles?(:administrator)
    else
      # OK / nothing raised
    end
  end

  def get_edit_view
    case @account
    when WjUser::OpenId
      "edit_open_id"
    when WjUser::BuiltIn::Administrator
      "edit_administrator"
    when WjUser::LocalDB
      "edit_local_db"
    end
  end

  def update_administrator
    if change_password
      @account.email = params[:account][:email]
      if @account.save
        flash.now[:info] = "Email and Password have been successfully updated."
      else
        flash.now[:error] = "Invalid email format. Password is not updated."
      end
    end
  end

  def update_local_db
    @account.display_name = params[:account][:display_name]
    unless params[:account][:current_password].blank? && params[:account][:new_password].blank?
      if change_password
        @account.save
        set_flash_now(:info, "Your account has been successfully updated (with a new password).")
      end
    else
      @account.save
        set_flash_now(:info, "Your account has been successfully updated (Your current password is not updated).")
    end
  end

  def change_password
    begin
      @account.change_password(params[:account][:new_password], params[:account][:current_password])
    rescue WjUser::LocalDatabaseAuth::InvalidOldPasswordError => e
      set_flash_now(:error, "Invalid Old Password!")
      false
    rescue WjUser::LocalDatabaseAuth::PasswordVerificationError => e
      set_flash_now(:error, "Password Policy Error : %s", e.message)
      false
    end
  end

end
