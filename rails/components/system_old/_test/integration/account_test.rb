require 'test_helper'

class AccountTest < ActionController::IntegrationTest
  def test_registration_with_open_id
  end

  def test_registration_with_password
    user = open_session
    user.get "/component/system/login/register_with_password"
    user.assert_response 200
    user.post system_accounts_path, :account => {
      :login_name => "test_user",
      :email => "test@example.com"
    }
    user.assert_redirected_to system_accounts_path("test_user")
    
  end

end
