require 'rubygems'
require File.join(File.dirname(__FILE__), "./util")

module Service
  #
  # OpenSocial appdata service implementation
  # Specification : http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/RPC-Protocol.html#AppData
  #
  # CouchDB Document Design:
  #
  #  {
  #    "_id"     : "app_data:{user_id}:{app_id}:{key}",
  #    "type"    : "AppData",
  #    "userId"  : "{user_id}",
  #    "appId"   : "{app_id}",
  #    "key"     : "{key}",
  #    "value"   : "{value}"
  #  }
  #
  #
  class Appdata
    # The service class name should be not AppData but Appdata because of System.apply method convention.
    class << self
      #
      # appdata.get
      #
      def get(params={}, token=nil, req=nil)
        params = {
          "userId"  => "@me",
          "groupId" => "@self",
          "appId"   => "@app",
          "keys"    => nil,
        }.update(params)

        app_id, user_ids = resolve_app_id_and_user_ids(params, token)

        result = nil
        if params["keys"] && params["keys"].is_a?(Array)
          option = {}
          option[:keys] = []
          user_ids.each { |uid|
            params["keys"].each {  |key|
              option[:keys] << [uid, app_id, key]
            }
          }
          # multi-key fetches for a reduce view must include group=true
          # and it cannot reduce with grouping.
          # thus, merging rows into one hash
          result = Util.db.view("app_data_by_ids", option)["rows"]
          result = result.inject({}){ |hash, item|
            key = item["key"].last
            val = item["value"]
            hash[key] = val
            hash
          }
        else
          # TODO optimization is required when user_ids is the large list.
          option = {}
          result = user_ids.inject({}) { |hash, uid|
            option[:startkey] = [uid, app_id]
            option[:endkey]   = [uid, app_id, "\u9999"]
            Util.db.view("app_data_by_ids", option)["rows"].each do |row|
              key = row["key"].last
              val = row["value"]
              hash[key] = val
            end
            hash
          }
        end

        # TODO consider the following case.
        #   The specification defines the return value as Map,
        #   which is ambigious when two or more users are specified
        #   For example
        #    userId="user1" has appdata, {"app_key" => "value1"}
        #    uesrId="user2" has appdata, {"app_key" => "value2"}
        #   In this case, when userId=["user1", "user2"], groupId="@self" is specified,
        #   what should appdata.get return?
        return result || {}
      end # def get

      def update(params={}, token=nil, req=nil)
        params = {
          "userId"  => "@me",
          "groupId" => "@self",
          "appId"   => "@app",
          "data"    => {},
        }.update(params)

        app_id, user_ids = resolve_app_id_and_user_ids(params, token)
        data = params["data"] || {}
        # building the data document.
        docs = []
        user_ids.each do |user_id|
          data.each do |k,v|
            doc = {
              "_id"     => "app_data:#{user_id}:#{app_id}:#{k}",
              "type"    => "AppData",
              "userId"  => user_id,
              "appId"   => app_id,
              "key"     => k,
              "value"   => v
            }
            doc["is_test_data"] = true if params["is_test_data"]
            docs.push(doc)
          end
        end

        # fetch the current document to set the _rev property
        keys = docs.map(){ |doc| doc["_id"] }
        current_docs_rev = Util.db.all_docs(:keys => keys)["rows"]

        docs.each_with_index do |doc, index|
          current = current_docs_rev[index]["value"]
          if current
            doc["_rev"] = current["rev"]
          end
        end

        # bulk save.
        result = Util.db.bulk_docs(docs, :all_or_nothing => true)
      end

      private
      def resolve_app_id_and_user_ids(params, token)
        app_id   = Util.replace_app_id(params["appId"], token)
        user_ids = Util.normalize_user_ids(params["userId"], token)
        user_ids = Util.resolve_user_ids_by_group_id(user_ids, params["groupId"])
        [app_id, user_ids]
      end

      def get_doc_id(app_id, user_id, key)
        "app_data:#{app_id}:#{user_id}:#{key}"
      end
    end
  end
end
