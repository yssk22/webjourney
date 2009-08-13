require 'rubygems'
require File.join(File.dirname(__FILE__), "../relax_client")
module Service
  #
  # Util class provides the common methods used in service implementation classes.
  #
  class Util
    @@db = RelaxClient.new("opensocial")
    class << self
      #
      # Returns the database client for backend opensocial database.
      #
      def db
        @@db
      end

      #
      # Normalize the use ids
      #
      # - if ids is not an array, it is converted to [ids].xs
      # - if each of ids is the placeholder such as '@me', it is ceonverted using the token.
      #
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
      # Returns the list of user ids for the specified group name.
      #
      def resolve_user_ids_by_group_id(user_ids, group_id, option = {})
        case group_id
        when "@self"
          return user_ids
        when "@friends"
          group_id = "friends"
        else
          # nothing to do
        end

        # return the list using "people_ids_in_relationship" view
        user_ids.map { |uid|
          opts = {
            :startkey => [uid, group_id].to_json,
            :endkey   => [uid, group_id, "\u0000"].to_json
          }
          db.view("people_ids_in_relationship",opts)["rows"].map { |r| r["key"].last }
        }.flatten
      end

      private
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
