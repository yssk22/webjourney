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

  def initialize(viewer_id, owner_id, app_id, domain_id, app_url, module_id, time)
    @viewer_id = viewer_id
    @owner_id  = owner_id
    @app_id    = app_id
    @domain_id = domain_id
    @app_url   = app_url
    @module_id = module_id
    @time      = time
  end

  class << self
    def from_request(req)
      oauth_req = OAuth::RequestProxy::RackRequest.new(req)
      if oauth_req.oauth_signature && oauth_req.oauth_consumer_key
        # TODO 2-legged oauth implemetation
      else
        # NOT OAuth Request, check st=xxx for Shindig specific security token
        token_string = req.params["st"]
        if token_string
          SecurityToken.from_string(token_string)
        else
          SecurityToken::ANONYMOUS
        end
      end
    end

    def from_string(token_string, encrypted = true)
      obj = if encrypted
              deserialize(decrypt(base64decode(token_string)))
            else
              deserialize(token_string)
            end
      # each objects are parsed as CGI.parse
      self.new(obj["v"].first,
               obj["o"].first,
               obj["a"].first,
               obj["d"].first,
               obj["u"].first,
               obj["m"].first,
               obj["t"].first)
    end

    private
    def deserialize(token_string)
      CGI.parse(token_string)
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
