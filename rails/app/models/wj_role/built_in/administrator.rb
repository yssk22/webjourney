class WjRole
  class BuiltIn
    class Administrator < BuiltIn
      NAME = "administrator"
      # Get administrator's account object (built-in)
      def self.me
        self.find_by_name(NAME)
      end
    end
  end
end
