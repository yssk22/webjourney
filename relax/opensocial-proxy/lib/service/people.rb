require 'rubygems'
require 'restclient'
#
# OpenSocial people service implementation
# Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#People
module Service
  class People
    class << self
      # get operation
      # params
      #  <tt>userId</tt>
      #  <tt>groupId</tt>
      def get(params={}, req = nil, token = nil)
        if params["groupId"] == "@self"
          # TODO handling the case params["userId"] is "@me".
          ids = params["userId"].is_a?(Array) ? params["userId"] : [params["userId"]]
          # Fetch the records from CouchDB

        end
        {
          "name"        => "Jane Doe",
          "displayName" => "Jone Doe",
          "gender"      => "female",
          "id"          => token.viewer_id
        }
      end
    end
  end
end
