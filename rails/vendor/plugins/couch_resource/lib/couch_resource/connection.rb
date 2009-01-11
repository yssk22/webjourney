require 'rubygems'
require 'active_support'
require 'json'
require 'net/https'
require 'uri'
require File.join(File.dirname(__FILE__), "error")

module CouchResource
  class ConnectionError < CouchResourceError # :nodoc:
    attr_reader :request
    attr_reader :response
    attr_reader :json

    def initialize(request, response, message = nil)
      @request  = request
      @response = response
      @json     = JSON(response.body) rescue nil
      @message  = message
    end

    def to_s
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
    end
  end

  # 3xx Redirection
  class Redirection < ConnectionError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
  end

  # 4xx Client Error
  class ClientError < ConnectionError; end # :nodoc:

  # 400 Bad Request
  class BadRequest < ClientError; end # :nodoc

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError; end # :nodoc

  # 403 Forbidden
  class ForbiddenAccess < ClientError; end # :nodoc

  # 404 Not Found
  class ResourceNotFound < ClientError; end # :nodoc:

  # 409 Conflict
  class ResourceConflict < ClientError; end # :nodoc:

  # 412 Precondition Failed
  class PreconditionFailed < ClientError; end

  # 5xx Server Error
  class ServerError < ConnectionError; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end

  class Connection
    attr_reader :site, :user, :password, :timeout
    attr_writer :user, :password, :timeout

    def initialize(site)
      raise ArgumentError, 'Missing site URI' unless site
      @user = @password = nil
      self.site = site
    end

    def site=(uri_string)
      @site = uri_string.is_a?(URI) ? uri_string : URI.parse(uri_string)
      @user = URI.decode(@site.user) if @site.user
      @password = URI.decode(@site.password) if @site.password
    end

    def get(path, headers = {})
      req = Net::HTTP::Get.new(path)
      set_request_headers(req, headers)
      request(req)
    end

    def delete(path, headers = {})
      req = Net::HTTP::Delete.new(path)
      set_request_headers(req, headers)
      request(req)
    end

    def put(path, body='', headers = {})
      req = Net::HTTP::Put.new(path)
      set_request_headers(req, headers)
      req.body = body
      request(req)
    end

    def post(path, body='', headers = {})
      req = Net::HTTP::Post.new(path)
      set_request_headers(req, headers)
      req.body = body
      request(req)
    end

    def head(path, body='', headers = {})
      req = Net::HTTP::Head.new(path)
      request(req)
    end

    private
    def request(req)
      res = http.request(req)
      handle_response(req, res)
    end

    # Handles response and error codes from remote service.
    def handle_response(request, response)
      case response.code.to_i
      when 301,302
        raise(Redirection.new(request, response))
      when 200...400
        response
      when 400
        raise(BadRequest.new(request, response))
      when 401
        raise(UnauthorizedAccess.new(request, response))
      when 403
        raise(ForbiddenAccess.new(request, response))
      when 404
        raise(ResourceNotFound.new(request, response))
      when 405
        raise(MethodNotAllowed.new(request, response))
      when 409
        raise(ResourceConflict.new(request, response))
      when 412
        raise(PreconditionFailed.new(request, response))
      when 422
        raise(ResourceInvalid.new(request, response))
      when 401...500
        raise(ClientError.new(request, response))
      when 500...600
        raise(ServerError.new(request, response))
      else
        raise(ConnectionError.new(request, response, "Unknown response code: #{response.code}"))
      end
      begin
        if response.body.blank?
          nil
        else
          hash = JSON(response.body)
          normalize_hash(hash)
        end
      rescue JSON::ParserError => e
        raise(ConnectionError.new(request, response, "Invalid json response: #{e.body}"))
      end
    end

    def normalize_hash(hash)
      hash.inject(HashWithIndifferentAccess.new({})) do |normalized, (k, v)|
        v = normalize_hash(v) if v.is_a?(Hash)
        normalized[k.to_sym] = v
        normalized
      end
    end

    def http
      http         = Net::HTTP.new(@site.host, @site.port)
      http.use_ssl = @site.is_a?(URI::HTTPS)
      http.verify_mode  = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
      http.read_timeout = @timeout if @timeout
      http
    end

    def default_header
      @default_header ||= {
        "Accept"       => "application/json",
        'Content-Type' => "application/json"
      }
    end


    def set_request_headers(request, headers={})
      headers = authorization_header.update(default_header).update(headers)
      headers.each do |k,v|
        request[k.to_s] = v
      end
    end

    # Sets authorization header
    def authorization_header
      (@user || @password ? { 'Authorization' => 'Basic ' + ["#{@user}:#{ @password}"].pack('m').delete("\r\n") } : {})
    end

  end
end
