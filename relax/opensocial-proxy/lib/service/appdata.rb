require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")

module Service
  #
  # OpenSocial appdata service implementation
  # Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#AppData
  #
  class Appdata
    # The service class name should be not AppData but Appdata because of System.apply method convention.
    class << self
      def get(params={}, token=nil, req=nil)
        params = {
          "userId"  => "@me",
          "groupId" => "@self",
          "appId"   => "@app",
          "keys"    => nil,
        }.update(params)

        app_id   = Util.replace_app_id(params["appId"], token)
        user_ids = Util.normalize_user_ids(params["userId"], token)
        user_ids = Util.resolve_user_ids_by_group_id(user_ids, params["groupId"])

        result = nil
        if params["keys"] && params["keys"].is_a?(Array)
          option = {}
          option[:keys] = []
          user_ids.each { |uid|
            params["keys"].each {  |key|
              option[:keys] << [uid, app_id, key]
            }
          }
          option[:group] = true # multi-key fetches for a reduce view must include group=true
          result = Util.db.view("app_data_by_ids", option)["rows"].first
        else
          # TODO optimization is required when user_ids is the large list.
          option = {}
          result = user_ids.map { |uid|
            option[:startkey] = [uid, app_id]
            option[:endkey]   = [uid, app_id, "\u0000"]
            Util.db.view("app_data_by_ids", option)["rows"].first
          }
          # TODO merge the result when two or more user ids are specified.
          # This should be fixed.
          result = result.first
        end

        # TODO consider the following case.
        #   The specification defines the return value as Map,
        #   which is ambigious when two or more users are specified
        #   For example
        #    userId="user1" has appdata, {"app_key" => "value1"}
        #    uesrId="user2" has appdata, {"app_key" => "value2"}
        #   In this case, when userId=["user1", "user2"], groupId="@self" is specified,
        #   what should appdata.get return?
        if result
          result["value"]
        else # result is nil
          {}
        end
      end
    end
  end
end
