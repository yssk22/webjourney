require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")
module Service
  #
  # OpenSocial Activities service implementation
  # Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#Activities
  #
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
        result = []
        total  = 0
        index  = 0
        if params["activityIds"] && params["activityIds"].is_a?(Array)
          option = {}
          option[:keys] = []
          user_ids.each { |uid|
            params["activityIds"].each {  |act_id|
              option[:keys] << [uid, app_id, act_id]
            }
          }
          raw_result = Util.db.view("activities_by_ids", option)
          result = raw_result["rows"].map { |row|
            row["value"]
          }
        else
          # TODO optimization is required when user_ids is the large list.
          option = {}
          result = user_ids.map { |uid|
            option[:startkey] = [uid, app_id]
            option[:endkey]   = [uid, app_id, "\u0000"]
            raw_result = Util.db.view("activities_by_ids", option)
            raw_result["rows"].map { |row|
              row["value"]
            }
          }
          result = result.flatten
        end

        {
          "totalResults" => result.length,
          "startIndex"   => 0,
          "itemsPerPage" => result.length,
          "list"         => result
        }

      end
      # get operation
      # params
      #  <tt>userId</tt>
      #  <tt>groupId</tt>
      #  <tt>appId</tt>
      #  <tt>activity</tt>
      def create(params={}, token=nil, req=nil)
        params = {
          "userId"      => "@me",
          "groupId"     => "@self",
          "appId"       => "@app",
          "activity"    => nil
        }.update(params)
        # read only fields
        app_id   = Util.replace_app_id(params["appId"], token)
        user_id  = Util.normalize_user_ids(params["userId"], token).first
        now      = Time.now
        activity = params["activity"].update({
                                               "type"   => "Activity",
                                               "userId" => user_id,
                                               "appId"  => app_id,
                                               "created_at" => now,
                                               "updated_at" => now,
                                               "postedTime" => now
                                             })
        Util.db.save(activity)
        return activity
      end
    end
  end
end
