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
      # <tt>params</tt> are:
      #   - <tt>userId</tt>
      #   - <tt>groupId</tt>
      def get(params={}, token=nil, req=nil)
        params = {
          "userId" => "@me",
          "groupId" => "@self",
        }.update(params)

        filters  = Util.extract_filters(params)
        user_ids = Util.normalize_user_ids(params["userId"], token)
        user_ids = Util.resolve_user_ids_by_group_id(user_ids, params["groupId"],
                                                     filters)

        # Get the opensocial.Person objects.
        # TODO search options such as sortOrder, count, ...
        query = { :keys => user_ids }
        query[:limit] = filters[:count] if filters[:count]
        query[:skip]  = filters[:startIndex] if filters[:startIndex]

        raw_result = Util.db.view("people_by_id",query)
        total_results = raw_result["total_rows"]
        start_index   = raw_result["offset"]
        result = raw_result["rows"].map do |row|
          # supporting PPL200
          # Shindig JsonRpc Requires isOwner and isViewer field.
          row["value"]["isOwner"]  = (row["key"] == token.owner_id)
          row["value"]["isViewer"] = (row["key"] == token.viewer_id)
          row["value"]
        end

        if !params["userId"].is_a?(Array) && params["groupId"] == "@self"
          result.first
        else
          # TODO we should fix result information.
          {
            "totalResults" => total_results,
            "startIndex"   => start_index,
            "itemsPerPage" => result.length,
            "list"         => result
          }
        end
      end

      #
      # create operation
      # <tt>params</tt> are:
      #   - <tt>userId</tt>
      #   - <tt>groupId</tt>
      #   - <tt>person</tt>
      #
      # This operation creates opensocial.Activity objects as the targets of a relationship with the specified user.
      #
      def create(params = {}, token = nil, req = nil)
        # TODO to be implemented
        raise LazyImplementationError.new
      end

      #
      # update operation
      # <tt>params</tt> are:
      #  - <tt>userId</tt>
      #  - <tt>groupId</tt>
      #  - <tt>person</tt>
      #
      # This operation update the opensocial.Person object identified by its relationship to the specified user.
      def update(params = {}, token = nil, req = nil)
        params = {
          "userId"  => "@me",
          "groupId" => "@self",
          "person"  => nil
        }.update(params)

        # (userId, groupId) must be the pair of (@me, @self)
        raise ArgumentError.new("userId must be '@me'")   if params["userId"]  != "@me"
        raise ArgumentError.new("groupId must be '@self") if params["groupId"] != "@self"
        raise ArgumentError.new("person must be filled")  if params["person"].nil?

        person = Util.db.load(Util.replace_user_id(params["userId"], token))
        new_person = update_person_doc(person, params["person"])
        new_person = Util.db.save(new_person)

        # alias id=_id
        new_person["id"] = new_person["id"]
        new_person
      end


      private

      ATTRIBUTES_TO_BE_KEPT = %w(_id _rev type)
      def update_person_doc(person_doc, attributes)
        kept_values = {}
        kept_values = ATTRIBUTES_TO_BE_KEPT.inject({}) do |hash, attr|
          hash[attr] = person_doc[attr] if person_doc.has_key?(attr)
          hash
        end
        person_doc.update(attributes).update(kept_values)
      end

    end
  end
end
