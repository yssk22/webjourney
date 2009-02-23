require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../functional_helper")

class AccountsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = System::AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_create_with_local_db
    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com",
        :type       => "local_db"
      }
    }
    assert_response 200
  end

  def test_create_with_open_id
    @controller.set_authenticated_open_id("http://open_id.example.com/test_user")
    post :create, {
      :account => {
        :login_name  => "test_oid",
        :open_id_uri => "http://open_id.example.com/test_user",
        :type        => "open_id"
      }
    }
    assert_response 200
  end

  def test_create_error_with_missing_type_parameter
    #== error case
    post :create, {
      :account => {
        :login_name => "test_user",
        :email      => "test_user@example.com"
      }
    }
    assert_response 400 # missing type parameter
  end

  def test_create_error_with_conflict_user
    post :create, {
      :account => {
        :login_name => "yssk22",
        :email      => "test_user@example.com",
        :type       => "local_db"
      }
    }
    assert_response 400 # conflict user
  end

  def test_update
    login(wj_users(:yssk22)) do
      put :update, {
        :id => "yssk22",
        :account => {
          :display_name => "Yohei Sasaki",
          :email        => "yssk22@example.com",
        }
      }
      assert_response 200
    end
  end

  def test_create_error_with_open_id_not_authenticated
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

  def test_password_reset
    post :password_reset, {
      :account => {
        :login_name => "yssk22",
        :email      => "yssk22@example.com"
      }
    }
    assert_response 200
  end

  def test_password_reset_error_with_invalid_account
    post :password_reset, {
      :account => {
        :login_name => "invalid_user",
        :email      => "invalid_user@example.com"
      }
    }
    assert_response 400
  end

  def test_password_with_passcode
    test_password_reset # password_reset request for yssk22
    yssk22 = wj_users(:yssk22)
    put :password, {
      :id      => "yssk22",
      :account => {
        :password         => "new_password",
        :request_passcode => yssk22.request_passcode
      }
    }
    assert_response 200
  end

  def test_password_with_retype
    login(wj_users(:yssk22)) do
      put :password, {
        :id      => "yssk22",
        :account => {
          :password         => "new_password",
          :password_retype  => "new_password"
        }
      }
      assert_response 200
    end
  end

  def test_password_error_with_password_verification_error
    test_password_reset # password_reset request for yssk22
    yssk22 = wj_users(:yssk22)
    put :password, {
      :id      => "yssk22",
      :account => {
        :password         => "",
        :request_passcode => yssk22.request_passcode
      }
    }
    # too short
    assert_response 400
  end

  def test_password_error_with_request_confirmation_error
    test_password_reset # password_reset request for yssk22
    yssk22 = wj_users(:yssk22)
    put :password, {
      :id      => "yssk22",
      :account => {
        :password         => "",
        :request_passcode => ""
      }
    }
    assert_response 400
  end

  def test_my_page_not_found
    page = WjPage.my_page_for("yssk22_openid", false)
    assert_nil page
    get :my_page, :id => "yssk22_openid"
    assert_response 404
  end

  def test_my_page_with_create
    login(wj_users("yssk22_openid")) do
      get :my_page, :id => "yssk22_openid"
      page = WjPage.my_page_for("yssk22_openid", false)
      assert_redirected_to page_url(page._id)
    end
  end

  def test_my_page
    test_my_page_with_create
    page = WjPage.my_page_for("yssk22_openid", false)
    get :my_page, :id => "yssk22_openid"
    assert_redirected_to page_url(page._id)
  end

  def test_activation
    test_create_with_local_db
    test_user = WjUser.find_by_login_name("test_user")
    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foobor",
        :request_passcode => test_user.request_passcode
      }
    }
    assert_response 200 # OK
  end

  def test_activation_error_with_password_verification_error
    test_create_with_local_db
    test_user = WjUser.find_by_login_name("test_user")
    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foo",
        :request_passcode => test_user.request_passcode
      }
    }
    assert_response 400 # too short password
  end

  def test_activation_error_with_request_confirmation_error
    test_create_with_local_db
    test_user = WjUser.find_by_login_name("test_user")
    post :activation, {
      :id => test_user.login_name,
      :account => {
        :password => "foobar",
        :request_passcode => "foobar"
      }
    }
    assert_response 400 # Invalid request passcode
  end

  def test_activation_error_with_invalid_status
    test_activation
    test_user = WjUser.find_by_login_name("test_user")
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

end
