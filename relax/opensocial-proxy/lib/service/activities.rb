require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")
#
# OpenSocial people service implementation
# Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#People
#
module Service
  class Activities
    class << self
      # get operation
      # params
      #  <tt>userId</tt>
      #  <tt>groupId</tt>
      #  <tt>activityIds</tt>
      def get(params={}, token=nil, req=nil)
        params = {
          "userId"      => "@me",
          "groupId"     => "@self",
          "activityIds" => nil
        }.update(params)
        app_id   = token.app_id
        user_ids = Util.normalize_user_ids(params["userId"], token)
        user_ids = Util.resolve_user_ids_by_group_id(user_ids, params["groupId"])

        # TODO search options such as sortOrder, count, ...

        # generating the keys
        #   when activityIds are specified, then use :keys option,
        #   otherwise, use :startkey and :endkey option.
        if params["activityIds"] && params["activityIds"].is_a?(Array)
          option = {}
          option[:keys] = user_ids.map { |uid|
            activityIds.map {  |act_id|
              [uid, app_id, act_id]
            }
          }
          Util.db.view("activities_by_ids", option)["rows"].map { |row|
            row["value"]
          }
        else
          # TODO optimization is required when user_ids is the large list.
          option = {}
          user_ids.map { |uid|
            option[:startkey] = [uid, app_id]
            option[:endkey]   = [uid, app_id, "\u0000"]
            Util.db.view("activities_by_ids", option)["rows"].map { |row|
              row["value"]
            }
          }.flatten
        end
      end

    end
  end
end
