module WjUser::LocalDatabaseAuth

  class InvalidOldPasswordError < WebJourney::Errors::ClientRequestError # :nodoc:
  end

  class PasswordVerificationError < WebJourney::Errors::ClientRequestError # :nodoc:
  end

  # the length of minumum password length
  MINIMUM_PASSWORD_LENGTH = 4

  # Get hash string for password
  def self.hash_password(str)
    Digest::MD5.hexdigest(str)
  end

  # Change the password to the new one. If <tt>old</tt> is passed, it is checked to be equal to the current.
  def change_password(new, old=nil)
    if old
      raise InvalidOldPasswordError if self.hash_password(old) != self.password_hash
    end
    verify_password(new)
    self.password_hash = self.hash_password(new)
  end

  def hash_password(str)
    WjUser::LocalDatabaseAuth.hash_password(str)
  end

  protected
  def verify_password(password)
    result = true
    raise PasswordVerificationError.new("Password is too short") unless (password.length > MINIMUM_PASSWORD_LENGTH)
  end

  def process_authenticate(credentials)
    option = credentials.symbolize_keys
    hash = self.hash_password(option[:password] || '')
    self.password_hash == hash
  end

end
