# The extension for functional tests
class Test::Unit::TestCase
  alias :open_session_org :open_session
  def login(user, password)
    session = open_session
    session.post current_system_accounts_path, :account => {
      :login_name => "yssk22"
    }, :password => "invalid password"
    session.assert_redirected_to current_system_accounts_path
    session
  end

end
