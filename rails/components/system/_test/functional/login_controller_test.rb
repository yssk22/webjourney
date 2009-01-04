require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class System::LoginControllerTest < ActiveSupport::TestCase
  def setup
    @controller = System::LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @config = WjConfig.instance
  end

  def test_index
    get :index
    assert_redirected_to :action => "with_password"
  end

  def test_with_password
    # GET
    get :with_password
    assert_response 200
    # POST with invalid password
    post :with_password, :account => { :login_name => "administrator", :password => "invalid password "}
    assert_response 400

    # POST with valid password
    post :with_password, :account => { :login_name => "administrator", :password => "password"}
    assert_equal "administrator", @controller.current_user.login_name
    assert_redirected_to mypage_system_account_path("administrator")
  end

  def test_with_open_id
    # GET
    get :with_open_id
    assert_response 200

    # POST with invalid OpenID URI (Found but negotiation failed)
    post :with_open_id, :account => { :open_id_uri => "http://localhost/dead_open_id" }
    assert_equal @response.flash.now[:error], @controller.class::Msg::OPENID_NEGOTIATION_FAILED
    assert_response 400

    # POST with invalid OpenID URI (Not found)
    post :with_open_id, :account => { :open_id_uri => "http://localhost/not_found" }
    assert_equal @response.flash.now[:error], @controller.class::Msg::OPENID_LOGIN_FAILED
    assert_response 400

    # POST with valid OpenID URI
    # This test should not be automated!!
    # post :with_open_id, :account => { :open_id_uri => "http://www.hatena.ne.jp/yssk22/" }
    # assert_response :redirect
  end

  def test_register_with_password
    @config.account_allow_local_db_register = true
    @config.save!
    get :register_with_password
    assert_response 200
  end

  def test_register_with_password_when_not_allowed
    @config.account_allow_local_db_register = false
    @config.save!
    get :register_with_password
    assert_response 403
  end

  def test_register_with_open_id
    @config.account_allow_open_id_register = true
    @config.save!
    get :register_with_open_id
    assert_response 200
  end

  def test_register_with_open_id_when_not_allowed
    @config.account_allow_open_id_register = false
    @config.save!
    get :register_with_open_id
    assert_response 403
  end
end
