require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")
module Service
  #
  # OpenSocial Messages service implementation
  # Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#Messages
  #
  class Messages
    class << self
      alias :_send :send
      #
      # params
      #  - "userId"
      #  - "message"
      #
      def send(params={}, token=nil, req=nil)
        params = {
          "userId"  => "@me",
          "message" => nil
        }.update(params)

        user_ids = Util.normalize_user_ids(params["userId"], token)
        from = user_ids.first
        # just store the Message document to the datastore
        if params["message"]
          doc = params["message"].dup.update({ "from" => from, "type" => "Message"} )
          Util.db.save(doc)
        else
          raise ArgumentError.new("message is null")
        end
        nil
      end
    end
  end
end
