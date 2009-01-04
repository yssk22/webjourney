class WjRole::BuiltIn::User < WjRole::BuiltIn
  NAME = "user"
  # Get account object (built-in)
  def self.me
    self.find_by_name(NAME)
  end
end
