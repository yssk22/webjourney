require 'openssl'
require 'net/http'
require 'uri'

module WebJourney
  module Util
    module Http
      HTTP_ACCEPT      = 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
      HTTP_USER_AGENT  = "WebJourney Feed Reader"
      REDIRECT_LIMIT   = 5

      def self.get_response(uri, options = {}, redirect = 0)
        options = {
          :open_timeout       => 60,
          :read_timeout       => 60,
          :user_agent         => HTTP_USER_AGENT
        }.update(options)
        uri = URI.parse(uri.to_s) unless uri.is_a?(URI)
        http_class = WjConfig.instance.http_class
        http = http_class.new(uri.host, uri.port)
        http.open_timeout = options[:open_timeout]
        http.read_timeout = options[:read_timeout]
        case uri.scheme
        when "http"
          # nothing to do
        when "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          raise ArgumentError.new("Invalid URI scheme: #{uri.to_s}")
        end
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Accept"]            = HTTP_ACCEPT
        req["User-Agent"]        = options[:user_agent] || HTTP_USER_AGENT
        req['If-Modified-Since'] = options[:if_modified_since] if options[:if_modified_since]
        req.basic_auth(options[:user] || uri.user, options[:password] || uri.password) if options[:user] or uri.user
        response = http.start { http.request(req) }
        if response.is_a?(Net::HTTPRedirection) && redirect < REDIRECT_LIMIT
          get_response(response["location"], options, redirect + 1)
        else
          response
        end
      end
    end
  end
end
