class WjUser
  #
  # Local database user class implemenatation.
  #
  class LocalDB < WjUser
    include WjUser::LocalDatabaseAuth
    class RequestConfirmationError < WebJourney::Errors::ClientRequestError # :nodoc:
    end


    validates_format_of :email,
    :with => /^([a-zA-Z0-9_\.\-]+)@([A-Za-z0-9_\.\-]+.[a-z]{2,})$/i,
    :allow_nil => false,
    :message => "format is not supported."

    # the length of request_passcode auto generated string
    PASSCODE_LENGTH = 32
    # the length of new password auto generated string
    NEW_PASSWORD_LENGTH = 8

    # Prepare a new local user.
    def self.prepare(login_name, email)
      obj = self.new()
      obj.login_name = login_name
      obj.email      = email
      obj.status     = WjUser::Status[:prepared]
      obj.set_request('register', 'register')
      obj.save
      obj
    end

    # Get the login method to display
    def login_method; "Password"; end

    # Activate a new local user.
    def activate(passcode, password)
      # verify reqest
      verify_request(WjUser::Status[:prepared], "register", passcode)
      verify_password(password)
      # verification passed
      self.password_hash =  self.hash_password(password)
      self.status = WjUser::Status[:active]
      self.clear_request
      self.wj_roles = WjRole.defaults
      self.save
    end

    # Prepare to reset password
    def request_to_reset_password()
      raise WjUser::InvalidStatusError.new("This account is not active.") unless self.active?
      self.set_request('reset_password', nil)
      self.save
    end

    # Commit to reset password
    def commit_to_reset_password(passcode, password)
      verify_request(WjUser::Status[:active], "reset_password", passcode)
      verify_password(password)
      # verification passed
      self.password_hash =  self.hash_password(password)
      self.clear_request
      self.save
    end

    # Set specified values request_key and request_value,
    # auto generated string request_passcode,
    # and current time request_at property.
    def set_request(key, value)
      self.request_passcode = generate_random_string(PASSCODE_LENGTH)
      self.request_key      = key
      self.request_value    = value
      self.request_at       = Time.now
    end

    # Clear all of request_[key|value|passcode|at] properties
    def clear_request
      self.request_passcode = nil
      self.request_key      = nil
      self.request_value    = nil
      self.request_at       = nil
    end

    protected
    def process_authenticate(credentials)
      if credentials.has_key?(:password)
        self.password_hash == self.hash_password(credentials[:password])
      elsif credentials.has_key?(:password_hash)
        self.password_hash == credentials[:password_hash]
      else
        false
      end
    end


    private
    def verify_request(status, key, passcode, wait = 30)
      raise RequestConfirmationError.new("invalid account status")           unless self.status == status
      raise RequestConfirmationError.new("request key mismatched")   unless self.request_key == key
      raise RequestConfirmationError.new("invalid request passcode") unless self.request_passcode == passcode
      raise RequestConfirmationError.new("passcode timeout")         unless Time.now < wait.minutes.since(self.request_at)
      logger.wj_info("Verification(#{key}) passed for #{self.login_name}.")
      true
    end


    def generate_random_string(length)
      a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      Array.new(length){a[rand(a.size)]}.join
    end
  end
end
