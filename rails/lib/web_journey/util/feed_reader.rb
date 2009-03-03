require 'openssl'
require 'net/http'
require 'uri'
require 'feed-normalizer'

module WebJourney
  module Util
    module FeedReader
      class FeedFetchError < WebJourney::Errors::ApplicationError
        def initialize(last_response, msg="failed to fetch feed.")
          super(msg)
          @last_response = last_response
        end

        def last_response
          @last_response
        end
      end

      HTTP_ACCEPT      = 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'
      HTTP_USER_AGENT  = "WebJourney Feed Reader"
      REDIRECT_LIMIT   = 5

      # Normalize uri (truncate the URI fragment)
      def self.normalize_uri(uri)
        uri = URI.parse(uri.to_s)
        uri.fragment = nil
        uri
      end

      # Fetch the feed target and returns a feed object.
      # <tt>options</tt> can be specified. if not specified, WjSiteConfig is used.
      #
      #  - :open_timeout
      #  - :read_timeout
      #  - :user_agent
      #  - :if_modified_since
      #
      # This method wraps HTTPResponse :
      #
      #  - when success, returns new feed object (if modified)
      #  - when failure, raise WebJourney::FeedReader::FeedFetchError
      #  - when redirect, retry request to the new location. If REDIRECT_LIMIT exceeds, then raise WebJourney::FeadReader::FeedFetchError
      #
      # The returned feed object is a result of FeedNormalizer::FeedNormalizer.parse(response).
      # See also FeedNormalizer project (http://code.google.com/p/feed-normalizer/)
      def self.fetch(uri, options = {}, count = 0)
        if count > REDIRECT_LIMIT
          raise FeedFetchError.new(response, "failed to fetch feed (too many redirections).")
        else
          begin
            uri = URI.parse(uri.to_s) unless uri.kind_of?(URI)
          rescue URI::InvalidURIError
            raise FeedFetchError.new(nil, "Invalid URI (#{uri.to_s})")
          end
          response = Http.get_response(uri, options)
          case response
          when Net::HTTPNotModified
            # parse is not needed.
            return [response, nil]
          when Net::HTTPSuccess
            # parse
            parsed = FeedNormalizer::FeedNormalizer.parse(response.body)
            if parsed
              return [response, parsed]
            else
              raise FeedFetchError.new(response, "failed to fetch feed (cannot parse response).")
            end
          when Net::HTTPRedirection
            fetch(response["location"], options, count + 1)
          else
            # HTTPClientError, HTTPServerError, HTTPUnknownResponse, HTTPInformation
            raise FeedFetchError.new(response)
          end
        end
      end
    end
  end
end
