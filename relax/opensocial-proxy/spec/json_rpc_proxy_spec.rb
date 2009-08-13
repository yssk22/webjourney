require 'rubygems'
require 'rack/test'
require File.join(File.dirname(__FILE__), '../lib/json_rpc_proxy')

include Rack::Test::Methods
def app
  JsonRpcProxy.new
end

ENDPOINT = "/rpc"

describe JsonRpcProxy, "when the HTTP method is not POST" do
  it "should response 405 error" do
    get ENDPOINT
    last_response.status.should be_equal(405)
  end
end

describe JsonRpcProxy, "when one of parameters is missing in the request." do
  it "should response 400 error with error message." do
    post ENDPOINT, { }.to_json
    last_response.status.should be_equal(400)
    JSON(last_response.body)["error"].should_not be_nil

    post ENDPOINT, [{}].to_json
    last_response.status.should be_equal(400)
    JSON(last_response.body)["error"].should_not be_nil
  end
end

# TODO 500 error specification to be described.
