require 'rubygems'
require File.join(File.dirname(__FILE__), "../relax_client")
#
# OpenSocial people service implementation
# Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#People
#
module Service
  class People
    @@db = RelaxClient.new("opensocial")

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

        user_ids = normalize_user_ids(params["userId"], token)
        # resolve the actual user ids to be fetched.
        case params["groupId"]
        when "@self"
          # nothing to do
        when "@friends"
          user_ids = fetch_relation_ids(user_ids, 'friends')
        else
          user_ids = fetch_relation_ids(user_ids, params["groupId"])
        end

        # TODO search options such as order
        raw_result = @@db.view("people_by_id",
                               :keys => user_ids)
        result = raw_result["rows"].map do |row|
          row["value"]
        end
        params["userId"].is_a?(Array) ? result : result.first
      end

      private
      def normalize_user_ids(ids, token)
        if ids.is_a?(Array)
          ids.map { |id|
            replace_user_id(id.to_s, token)
          }
        else
          normalize_user_ids([ids], token)
        end
      end

      #
      # Replace placeholder (that starts with '@') to the actual value derived from the request token
      #
      def replace_user_id(value, token)
        return value unless value =~ /^@.+/
        case value
          when "@me"
          token.viewer_id
          else
          value
        end
      end
    end
  end
end
