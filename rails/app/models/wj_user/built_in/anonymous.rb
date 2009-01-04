class WjUser::BuiltIn::Anonymous < WjUser::BuiltIn

  NAME = "anonymous"
  # Get account object (built-in)
  def self.me
    self.find_by_login_name(NAME)
  end

  protected
  def process_authenticate(credentials)
    wj_info("Authentication is not required for WjUser::BuiltIn::Anonymous")
    true
  end
end
