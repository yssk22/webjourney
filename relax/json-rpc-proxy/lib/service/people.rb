require 'rubygems'
require 'restclient'
#
# OpenSocial people service implementation
# Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#People
#
module Service
  class People
    class << self
      # get operation
      def get(params={}, req = nil)
        {
          "name"        => "Jane Doe",
          "displayName" => "Jone Doe",
          "gender"      => "female",
          "id"          => "example.org:34KJDCSKJN2HHF0DW20394"
        }
      end
    end
  end
end
