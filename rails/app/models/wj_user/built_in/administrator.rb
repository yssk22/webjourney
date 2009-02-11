class WjUser
  class BuiltIn
    #
    # Built-in user class represents the administrator.
    #
    class Administrator < BuiltIn
      include WjUser::LocalDatabaseAuth
      NAME = "administrator"
      # Get administrator's account object (built-in)
      def self.me
        self.find_by_login_name(NAME)
      end
    end
  end
end

