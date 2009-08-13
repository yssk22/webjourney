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
        case params["groupId"]
        when "@self"
          # nothing to do
        when "@friends"
          # @friends interpreted as groupId="friend"
          # Get the people ids in the group tagged with {groupId}
          user_ids = people_ids_in_group(user_ids, "friends")
        else
          user_ids = people_ids_in_group(user_ids, params["groupId"])
        end

        # Get the opensocial.Person objects.
        # TODO search options such as sortOrder, count, ...
        raw_result = @@db.view("people_by_id",
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

      private
      def people_ids_in_group(user_ids, group_name)
        user_ids.map { |uid|
          opts = {
            :startkey => [uid, group_name].to_json,
            :endkey   => [uid, group_name, "\u0000"].to_json
          }
          @@db.view("people_ids_in_group",opts)["rows"].map { |r| r["key"].last }
        }.flatten
      end

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
