require 'rubygems'
require 'restclient'
#
# OpenSocial system service
#
module Service
  class People
    class << self
      def get(params={}, req = nil)
        {
          "name" => "Jane Doe",
          "displayName" => "Jone Doe",
          "gender" => "female",
          "id" => "example.org:34KJDCSKJN2HHF0DW20394"
        }
      end
    end
  end
end
