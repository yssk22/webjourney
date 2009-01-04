class WjRole::BuiltIn::Administrator < WjRole::BuiltIn
  NAME = "administrator"
  # Get administrator's account object (built-in)
  def self.me
    self.find_by_name(NAME)
  end
end
