class WjUser::BuiltIn < WjUser
  before_create  :dont_create_built_in_accounts
  before_destroy :dont_destroy_built_in_accounts
  protected
  def dont_create_built_in_accounts
    assert_failure "built-in account (#{self.login_name}) should not be created.Use fixture to setup initially)"
  end
  def dont_destroy_built_in_accounts
    assert_failure "built-in account (#{self.login_name}) should not be destroyed."
  end
end
