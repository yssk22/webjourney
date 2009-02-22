require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class ComponentControllerTest < ActiveSupport::TestCase
  def setup
    @controller = System::AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @config     = WjConfig.instance
  end

  def test_index
    login(wj_users(:administrator)) do
      get :index
      assert_response 200
      get :index, { :type => "open_id" }
      assert_response 200
      get :index, { :type => "password" }
      assert_response 200
    end

    get :index
    assert_response 401
    login(wj_users(:yssk22)) do
      get :index
      assert_response 403
    end
  end

  def test_with_new
    get :new, { :type => "password" }
    assert_response 200
    get :new, { :type => "open_id" }
    assert_response 200
    get :new, { :type => "unknown" }
    assert_response 400
  end

  def test_with_when_not_allowed
    @config.account_allow_local_db_register = false
    @config.account_allow_open_id_register = false
    @config.save!
    get :new, { :type => "password" }
    assert_response 403
    get :new, { :type => "open_id" }
    assert_response 403

    post :create, { :type => "password" }
    assert_response 403
    post :create, { :type => "open_id" }
    assert_response 403
  end

  def test_create
    post :create, { :type => "password",
      :account => {
        :login_name => "new_local_db",
        :email      => "new_local_db@example.com"
      }
    }
    assert_redirected_to system_account_path("new_local_db")
    # duprecated creation
    post :create, { :type => "password",
      :account => {
        :login_name => "new_local_db",
        :email      => "new_local_db@example.com"
      }
    }
    assert_response 400
    #
    # -- OpenID
    #
    post :create, { :type => "open_id",
      :account => {
        :login_name  => "new_open_id",
        :open_id_uri => "http://localhost//new_open_id"
      }
    }
    assert_redirected_to system_account_path("new_open_id")

    # duprecated creation
    post :create, { :type => "open_id",
      :account => {
        :login_name  => "new_open_id",
        :open_id_uri => "http://localhost//new_open_id"
      }
    }
    assert_response 400
  end

  def test_show
    get :show,  {  :id => "prepared_test_user"}
    assert_response 200

    get :show,  {  :id => "active_test_user"}
    assert_response 200

    get :show,  {  :id => "locked_test_user"}
    assert_response 401

    get :show,  {  :id => "destroyed_test_user"}
    assert_response 404

    # administrator account access
    login(wj_users(:administrator)) do
      get :show,  {  :id => "locked_test_user"}
      assert_response 200

      get :show,  {  :id => "destroyed_test_user"}
      assert_response 200
    end

    # user account access
    login(wj_users(:yssk22)) do
      get :show,  {  :id => "locked_test_user"}
      assert_response 403

      get :show,  {  :id => "destroyed_test_user"}
      assert_response 404
    end
  end


=begin
  def test_create_with_password
    post :create, :type => "password", :account => {
      :login_name => "test",
      :email      => "test@example.com"
    }
    assert_redirected_to system_account_path(:test)
  end

  def test_current
    get :current
    assert_response 404
    post :current, :account => {
      :login_name => "yssk22"
    }, :password => "invalid password"
    assert_response 400
    post :current, :account => {
      :login_name => "yssk22"
    }, :password => "password"
    assert_redirected_to current_system_accounts_path
    get :current
    assert_response 200
    delete :current
    assert_response 200
    delete :current
    assert_response 404
  end
=end
end
