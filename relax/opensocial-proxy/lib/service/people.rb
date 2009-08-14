require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")

module Service
  #
  # OpenSocial people service implementation
  # Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#People
  #
  class People
    class << self
      # get operation
      # params
      #  <tt>userId</tt>
      #  <tt>groupId</tt>
      def get(params={}, token=nil, req=nil)
        params = {
          "userId" => "@me",
          "groupId" => "@self",
        }.update(params)

        user_ids = Util.normalize_user_ids(params["userId"], token)
        user_ids = Util.resolve_user_ids_by_group_id(user_ids, params["groupId"])

        # Get the opensocial.Person objects.
        # TODO search options such as sortOrder, count, ...
        raw_result = Util.db.view("people_by_id",
                                  :keys => user_ids)
        result = raw_result["rows"].map do |row|
          row["value"]
        end

        if !params["userId"].is_a?(Array) && params["groupId"] == "@self"
          # returns person object
          result.first
        else
          # returns array of person objects.
          result
        end
      end
    end
  end
end
