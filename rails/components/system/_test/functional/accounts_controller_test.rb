require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class AccountsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = System::AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_create
    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com",
        :type       => "local_db"
      }
    }
    assert_response 200

    @controller.set_authenticated_open_id("http://open_id.example.com/test_user")
    post :create, {
      :account => {
        :login_name  => "test_oid",
        :open_id_uri => "http://open_id.example.com/test_user",
        :type        => "open_id"
      }
    }
    assert_response 200

    #== error case
    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com"
      }
    }
    assert_response 400 # missing type parameter

    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com",
        :type       => "local_db"
      }
    }
    assert_response 400 # conflict user

    @controller.set_authenticated_open_id(nil)
    post :create, {
      :account => {
        :login_name  => "test_oid2",
        :open_id_uri => "http://open_id.example.com/test_user",
        :type        => "open_id"
      }
    }
    assert_response 400 # open id is not authenticated
  end

  def test_activation
    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com",
        :type       => "local_db"
      }
    }
    assert_response 200

    test_user = WjUser.find_by_login_name("test_user")
    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foo",
        :request_passcode => test_user.request_passcode
      }
    }
    assert_response 400 # too short password

    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foobar",
        :request_passcode => "foobar"
      }
    }
    assert_response 400 # Invalid request passcode

    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foobor",
        :request_passcode => test_user.request_passcode
      }
    }
    assert_response 200 # OK

    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foobor",
        :request_passcode => test_user.request_passcode
      }
    }
    assert_response 400 # Invalid status

  end

  def test_current_get
    get :current
    assert_response 405
  end

  def test_current_post
    post :current
    assert_response 405
  end

  def test_current_put
    put :current, :account => {
      :login_name => "administrator",
      :password   => "password"
    }, :format => "json"
    assert_response 200

    put :current, :account => {
      :login_name => "administrator",
      :password   => "invalid_password"
    }, :format => "json"
    assert_response 400
  end

  def test_current_delete
    delete :current
    assert_response 200
  end

  def test_my_page_get
    page = WjPage.my_page_for("yssk22_openid", false)
    assert_nil page
    get :my_page, :id => "yssk22_openid"
    assert_response 404

    login(wj_users("yssk22_openid")) do
      get :my_page, :id => "yssk22_openid"
      page = WjPage.my_page_for("yssk22_openid", false)
      assert_redirected_to page_url(page._id)
    end

    get :my_page, :id => "yssk22_openid"
    assert_redirected_to page_url(page._id)
  end

end
