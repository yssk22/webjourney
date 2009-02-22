#
# == Account Resource [components/system/accounts]
class System::AccountsController < WebJourney::ResourceController
  before_filter :load_account, :only => [:show, :destroy, :password, :my_page, :activation]

  def index
  end

  def show
  end

  def edit
  end

  # == system/accounts/{login_name}
  # === POST
  # Create a new account
  # ==== Request
  #
  # <tt>account[type]</tt>:: "local_db" or "open_id"
  #
  # When <tt>account[type]</tt> is "local_db", following parameters are required:
  #
  # <tt>account[login_name]</tt>::
  # <tt>account[email]</tt>::
  #
  # When <tt>account[type]</tt> is "open_id", following parameters are required:
  #
  # <tt>account[login_name]</tt>::
  # <tt>account[open_id_uri]</tt>::
  #
  def create
    case type = params[:account][:type]
    when "local_db", "open_id"
      # OK
    else
      client_error!("Invalid account type: #{type}")
    end
    if send "create_#{type}"
      respond_to_ok(@account)
    else
      respond_to_error(error_resource_for(:account))
    end
  end

  def update
  end

  def destroy
  end

  # == system/accounts/password_reset
  # End Point to start resetting password process.
  #
  # === POST
  # Generate a comfirmation url for reset password (system/accounts/{login_name}/password?request_passcode={code})
  # which is delivered by email
  # ==== Request
  #
  # <tt>account[login_name]</tt>::
  # <tt>account[email]</tt>::
  #
  # ==== Response Examples
  # - success (status: 200)
  #
  #   {"reset_password" => "started"}
  #
  # - failure (status: 400)
  #
  #   {
  #      account : {
  #         errors     : [error_reason],
  #         login_name : []
  #         password   : []
  #      }
  #   }
  def password_reset
    @account = WjUser::LocalDB.find_by_login_name_and_email(params[:account][:login_name], params[:account][:email])
    if @account
      @account.request_to_reset_password
      System::Mailer.deliver_reset_password_confirmation(@account,
                                                         confirm_reset_password_url_for(@account))
      respond_to_ok({:reset_password => :started})
    else
      errors = {
        :account => {
          :errors     => ["Invalid Login name or Email."],
          :login_name => [],
          :email      => []
        }
      }
      respond_to_error(errors)
    end
  end

  # == system/accounts/{login_name}/activation
  # URI endpoint for Local DB users to update password.
  # === PUT
  # Update the password of the account specified by {login_name}.
  # ==== Request
  #
  # <tt>account[request_passcode]</tt>::
  # <tt>account[password]</tt>::
  #
  # ==== Response Examples
  # - success (status: 200)
  #
  #   {"password" : "ok" }
  #
  # - failure (status: 400)
  #
  #   {
  #      account : {
  #         password   : [error_reason]
  #         request_passcode   : [error_reason]
  #      }
  #   }
  #
  def password
    begin
      @account.commit_to_reset_password(params[:account][:request_passcode], params[:account][:password])
      respond_to_ok({:password => :ok})
    rescue WjUser::LocalDatabaseAuth::PasswordVerificationError => e
      respond_to_error({ :account => {
                           :password  => [e.message]
                         }})
    rescue WjUser::LocalDB::RequestConfirmationError => e
      respond_to_error({ :account => {
                           :request_passcode => [e.message]
                         }})
    end
  end

  # == system/accounts/{login_name}/my_page
  # end point to redirect the user's "my page" redirection.
  #
  # === GET
  # This url always redirects to the user's my page if found.
  # When the current user accesss to this uri and the page is not found, it is automatically created.
  #
  def my_page
    case request.method
    when :get
      page = WjPage.my_page_for(@account.login_name, current_user.login_name == @account.login_name)
      not_found! unless page
      redirect_to page_url(page._id)
    else
      method_not_allowed!
    end
  end

  # == system/accounts/{login_name}/activation
  # Activation URI endpoint for Local DB users
  # === POST
  # Activate the user account specified by {login_name}.
  # ==== Request
  #
  # <tt>account[request_passcode]</tt>::
  # <tt>account[password]</tt>::
  #
  # ==== Response Examples
  # - success (status: 200)
  #
  #   { activation: "ok" }
  #
  # - failure (status: 400)
  #
  #   {
  #      account : {
  #         password   : [error_reason]
  #         request_passcode   : [error_reason]
  #      }
  #   }
  #
  def activation
    begin
      @account.activate(params[:account][:request_passcode], params[:account][:password])
      respond_to_ok({:activation => :ok})
    rescue WjUser::LocalDatabaseAuth::PasswordVerificationError => e
      respond_to_error({ :account => {
                           :password  => [e.message]
                         }})
    rescue WjUser::LocalDB::RequestConfirmationError => e
      respond_to_error({ :account => {
                           :request_passcode => [e.message]
                         }})
    end
  end

  # == system/accounts/current
  # This is a RESTful representation for the 'login/logout' mechanism.
  #
  # === PUT
  # Create a relation between the user and the client cookie.
  #
  # ==== Request
  #
  # <tt>account[login_name]</tt>::
  # <tt>account[password]</tt>::
  #
  # ==== Response Examples
  # - success (status: 200)
  #
  #   { "my_page_url" : "http://.../" }
  #
  # - failure (status: 400)
  #
  #   {
  #      account : {
  #         errors     : [error_reason],
  #         login_name : []
  #         password   : []
  #      }
  #   }
  #
  # === DELETE
  # Delete a relation between the user and and the client cookie.
  #
  # ==== Response Examples
  # - success (status: 200)
  #
  #   {}
  #
  def current
    case request.method
    when :put
      @account = WjUser.find_by_login_name(params[:account][:login_name])
      if !@account.nil? && @account.authenticate(:password => params[:account][:password])
        set_current_user(@account)
        respond_to_ok({ :my_page_url => my_page_system_account_url(@account.login_name)})
      else
        errors = {
          :account => {
            :errors     => ["Invalid Login name or Password."],
            :login_name => [],
            :password   => []
          }
        }
        respond_to_error(errors)
      end
    when :delete
      respond_to_nothing
    else
      method_not_allowed!
    end
  end

  private
  def load_account
    @account = WjUser.find_by_login_name(params[:id])
    not_found! unless @account
  end

  def create_local_db
    @account = WjUser::LocalDB.prepare(params[:account][:login_name],
                                       params[:account][:email])
    return false if @account.new_record?
    # send notification mail
    System::Mailer.deliver_registration_confirmation(@account,
                                                     activation_url_for(@account))
    true
  end

  def create_open_id
    client_error!("request is invalid: Not authenticated.") unless params[:account][:open_id_uri] == get_authenticated_open_id
    # TODO check the valid open id uri (vaildate already authenticated?)
    @account = WjUser::OpenId.prepare(params[:account][:login_name],
                                      params[:account][:open_id_uri])
    if !@account.new_record?
      @account.activate
    else
      false
    end
  end

  def activation_url_for(account)
    url_for(:controller => "login_page",
            :action => "activation",
            :params => {
              :login_name       => account.login_name,
              :request_passcode => account.request_passcode
            })
  end

  def confirm_reset_password_url_for(account)
    url_for(:controller => "login_page",
            :action => "confirm_reset_password",
            :params => {
              :login_name       => account.login_name,
              :request_passcode => account.request_passcode
            })
  end

end
