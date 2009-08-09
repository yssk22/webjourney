requrie 'rubygems'
require 'restclient'

class People
  class << self
    #
    # Returns profiles for guids
    #
    # Supported API:
    #   /people/{guid}/@self
    #   /people/@me/@self     # @me should be resolved to the guid of the requester
    #
    def get_profiles_by_guids(guids)

    end

    #
    # Returns a coolection of all friends of user {guid}
    #
    # Supported API:
    #   /people/{guid}/@self
    #   /people/@me/@self     # @me should be resolved to the guid of the requester
    #
    def get_friends_by_guids()
    end

    #
    # Returns a coolection of all people connected to user {guid}
    #
    # Supported API:
    #   /people/{guid}/@self
    #   /people/@me/@self     # @me should be resolved to the guid of the requester
    #
    def get_all_by_guids()
    end
  end
end
