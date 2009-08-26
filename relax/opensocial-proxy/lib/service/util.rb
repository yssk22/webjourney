require 'rubygems'
require File.join(File.dirname(__FILE__), "../../../relax_client/lib/relax_client")
module Service
  #
  # An exception raised when the service is not suppored.
  #
  class NotSupportedError < StandardError; end

  #
  # An exception raised when the service should be supported but not yet.
  #
  class LazyImplementationError < NotSupportedError; end

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
    end
  end

  module Util::Ids
    POSITIVE_INT_FILTER_KEYS   = %w(count startIndex networkDistance)
    STRING_FILTER_KEYS = %w(sortBy filterBy)
    #
    # Returns the parameters in the parameters
    #
    def extract_filters(params = {})
      filter = {}
      POSITIVE_INT_FILTER_KEYS.each do |key|
        v = params[key].to_i
        filter[key.to_sym] = v if params.has_key?(key) && v >= 0
      end
      STRING_FILTER_KEYS.each do |key|
        v = params[key].to_s
        filter[key.to_sym] = params[key] if params.has_key?(key) && v.length > 0
      end
      filter
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
    def resolve_user_ids_by_group_id(user_ids, group_id, filter = {})
      if is_placeholder?(group_id)
        case group_id
        when "@self"
          return user_ids
        else
          group_id = replace_group_id(group_id)
        end
      end

      # return the list using "people_ids_in_relationship" view
      result = []
      result = user_ids.map { |uid|
        opts = {
          :startkey => [uid, group_id],
          :endkey   => [uid, group_id, "\u0000"]
        }
        db.view("people_ids_in_relationship",opts)["rows"].map { |r| r["key"].last }
      }
      result.flatten!
    end

    #
    # Replace placeholder (that starts with '@') for userId to the actual value derived from the request token
    #
    def replace_user_id(value, token)
      return value unless is_placeholder?(value)
      case value
      when "@me"
        token.viewer_id
      when "@owner"
        token.owner_id
      when "@viewer"
        token.viewer_id
      else
        raise ArgumentError.new("Unknown placeholder (userId='#{value}')")
      end
    end

    #
    # Replace placeholder (that starts with '@') for appId to the actual value derived from the request token
    #
    def replace_app_id(value, token)
      return value unless is_placeholder?(value)
      case value
      when "@app"
        token.app_id
      else
        raise ArgumentError.new("Unknown placeholder (appId='#{value}')")
      end
    end

    #
    # Replace placeholder (that starts with '@') for groupId to the actual value.
    #
    def replace_group_id(value)
      return value unless is_placeholder?(value)
      case value
      when "@friends"
        "friends"
      else
        raise ArgumentError.new("Unknown placeholder (groupId='#{value}')")
      end
    end

    def is_placeholder?(v)
      v =~ /^@.+/
    end
  end


  Util.extend(Util::Ids)
end
