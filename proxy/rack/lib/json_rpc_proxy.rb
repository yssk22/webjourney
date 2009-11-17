require 'rubygems'
require 'json'

require File.join(File.dirname(__FILE__), 'security_token')
require File.join(File.dirname(__FILE__), 'service/system')

class JsonRpcProxy
  DEFAULT_RESPONSE_HEADER = {
    'Content-Type'=>'application/json'
  }

  class JsonRpcError < StandardError;  end

  def initialize
  end

  # Rack application handling
  def call(env)
    status          = 200
    response_header = DEFAULT_RESPONSE_HEADER.dup
    body            = nil
    begin
      req = Rack::Request.new(env)
      if req.post?
        json = JSON.parse(req.body.read)
        if json.is_a?(Array) # json-rpc batch request
          body = json.map { |rpc|
            dispatch(rpc, req)
          }
        else # json-rpc single request
          body = dispatch(json, req)
        end
      else
        # Invalid JSON RPC.
        status = 405
        body   = {}
      end
    rescue JsonRpcError => e
      status = 400
      body   = {"error" => "Invalid JSON RPC request(At least one of method, params, or id is missing)"}
    rescue JSON::ParserError => e
      status = 400
      body   = {"error" => "Invalid JSON RPC request(JSON format could not be parsed.)"}
    rescue => e
      status = 500
      body   = {"error" => e.message, "trace" => e.backtrace[0..3]}
    end
    # returns Rack style response array.
    body = body.to_json
    response_header["Content-Length"] = body.length.to_s
    return [status, response_header, body]
  end

  private
  # dispatch the rpc request
  def dispatch(rpc, req)
    validate!(rpc)
    # dispatch the rpc request
    service, method = rpc["method"].split(".")
    result = Service::System.apply(service, method, rpc["params"], SecurityToken.from_request(req), req)
    # TODO
    #   Currently shindig implementation required 'data' field, not 'result' field.
    #   This should be changed.
    return {
      "id"     => rpc["id"],
      "data"   => result
    }
  end

  def validate!(rpc)
    unless (rpc.has_key?("method") && rpc.has_key?("params") && rpc.has_key?("id"))
      raise JsonRpcError.new
    end
  end
end
