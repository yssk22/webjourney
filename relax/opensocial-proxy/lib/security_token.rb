require 'cgi'
#
# Security Token Implementation
#
# This implementation depends on the CouchDB security token implementation
# in relax/apps/webjourney/lib/helpers/securityToken.js
#
class SecurityToken

  attr_reader :owner_id
  attr_reader :viewer_id
  attr_reader :app_id
  attr_reader :domain_id
  attr_reader :app_url
  attr_reader :module_id
  attr_reader :time

  def initialize(owner_id, viewer_id, app_id, domain_id, app_url, module_id, time)
    @owner_id  = owner_id
    @viewer_id = viewer_id
    @app_id    = app_id
    @domain_id = domain_id
    @app_url   = app_url
    @module_id = module_id
    @time      = time
  end

  class << self
    def from_string(token_string)
      obj = deserialize(decrypt(base64decode(token_string)))
      self.new(obj["o"],
               obj["v"],
               obj["a"],
               obj["d"],
               obj["u"],
               obj["m"],
               obj["t"])
    end

    def deserialize(token_string)
      obj = CGI.parse(token_string)
    end

    def base64decode(token_string)
      # TODO to be implemented
      token_string
    end

    def decrypt(token_string)
      # TODO to be implemented
      token_string
    end
  end

end

SecurityToken::ANONYMOUS = SecurityToken.new("anonymous", "anonymous", "", "", "", "", Time.new)
